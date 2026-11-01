/// The whole Forums API client. Every network call in the app is in this file.
///
/// Docs: https://forums.simpleapi.dev/docs
///
/// Two rules apply to every request:
///  * the API key goes in the `apikey` query string (an `APIKEY` header also works);
///  * calls that write data also send `Authorization: Bearer <token>`, where
///    the token comes from [ForumsApi.register] / [ForumsApi.login]. The
///    client never sends an owner: the API uses the logged-in user.
///
/// Reading needs no login, so reads leave the token out. A token that has run
/// out would otherwise turn a public list into a 401.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Thrown for any non-2xx answer. [message] is the API's own `message` when it
/// sent one, e.g. "The selected status is invalid.". [statusCode] is 0 when
/// the API could not be reached at all.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.sessionEnded = false});

  final int statusCode;
  final String message;

  /// True when this was a 401 on a call made while logged in and the login
  /// token was the problem. The client has already dropped the token.
  final bool sessionEnded;

  /// True for a 401 that says the API key was not accepted.
  bool get keyRejected => statusCode == 401 && RegExp(r'api ?key', caseSensitive: false).hasMatch(message);

  @override
  String toString() => message;
}

/// Values the API accepts (it answers 422 for anything else). Status is one of
/// Draft, Active, Locked, Removed, Pending Review; topic type is one of Post,
/// Video, Article, Image.
const contentStatus = 'Active';
const topicType = 'Post';

/// Report types: Noncompliant, Offensive, Other. The sample offers the last two.
const reportTypes = ['Offensive', 'Other'];

/// Called when a call made while logged in is answered with a 401 about the
/// login token. The token has been dropped by then.
typedef SessionExpiredCallback = void Function();

/// The most rows the API gives per page.
const _perPage = 100;

class ForumsApi {
  ForumsApi({
    required this.apiKey,
    this.token,
    http.Client? client,
    this.host = 'forums.simpleapi.dev',
    this.onSessionExpired,
  }) : _http = client ?? http.Client();

  final String apiKey;
  final String host;

  /// Told when the login token stops working (see [SessionExpiredCallback]).
  final SessionExpiredCallback? onSessionExpired;

  /// Set after [login] / [register]; sent as the Bearer token.
  String? token;

  final http.Client _http;

  // ---------------------------------------------------------------- reading

  /// GET /api/forums - all forums of this key (an empty list at first).
  Future<List<Forum>> listForums() async {
    return [for (final f in await _allRows('/api/forums')) Forum.fromJson(f)];
  }

  /// GET /api/forums/{slug}/topics - topics in a forum.
  Future<List<Topic>> listTopics(String forumSlug) async {
    return [for (final t in await _allRows('/api/forums/${Uri.encodeComponent(forumSlug)}/topics')) Topic.fromJson(t)];
  }

  /// GET /api/topics/{slug} - one topic with its whole comment tree
  /// (replies nested under `comments`). Looked up by slug, not by id.
  Future<Topic> getTopic(String topicSlug) async {
    final json = await _send('GET', '/api/topics/${Uri.encodeComponent(topicSlug)}', authenticated: false);
    return Topic.fromJson(json);
  }

  // ------------------------------------------------------------------ users

  /// POST /api/users/register - create a user that belongs to this key.
  /// Answers 201 with `{token, expires_at, user}`, or 202 (no token) when the email is the one the
  /// key belongs to and a confirmation code was emailed instead.
  Future<AuthResult> register({required String name, required String email, required String password}) async {
    final json = await _send('POST', '/api/users/register', authenticated: false, body: {'name': name, 'email': email, 'password': password});
    return _authResult(json);
  }

  /// POST /api/users/login - answers `{token, expires_at, user}`.
  Future<AuthResult> login({required String email, required String password}) async {
    final json = await _send('POST', '/api/users/login', authenticated: false, body: {'email': email, 'password': password});
    return _authResult(json);
  }

  /// POST /api/users/logout - ends this session. Other sessions stay.
  Future<void> logout() async {
    await _send('POST', '/api/users/logout', body: const {});
    token = null;
  }

  AuthResult _authResult(Map<String, dynamic> json) {
    final result = AuthResult.fromJson(json);
    if (result.token != null) token = result.token;
    return result;
  }

  // ---------------------------------------------------------------- writing
  // Everything below needs a logged-in user (Bearer token).

  /// POST /api/forums - create a forum. Basic keys are limited to 7 forums (the 8th answers 403).
  Future<Forum> createForum({required String title, String? body}) async {
    final json = await _send('POST', '/api/forums', body: {
      'title': title,
      'status': contentStatus,
      if (body != null && body.isNotEmpty) 'body': body,
    });
    return Forum.fromJson(json);
  }

  /// DELETE /api/forums/{id} - delete a forum you created.
  Future<void> deleteForum(int id) async {
    await _send('DELETE', '/api/forums/$id');
  }

  /// POST /api/forums/{id}/topics - start a topic in a forum.
  /// `body` is optional (it defaults to an empty text).
  Future<Topic> createTopic(int forumId, {required String title, String? body}) async {
    final json = await _send('POST', '/api/forums/$forumId/topics', body: {
      'title': title,
      'status': contentStatus,
      'type': topicType,
      if (body != null && body.isNotEmpty) 'body': body,
    });
    return Topic.fromJson(json);
  }

  /// PUT /api/topics/{id} - edit the text of your own topic. A PUT changes
  /// only what is sent, so the status stays as it is.
  Future<Topic> updateTopic(int id, {required String body}) async {
    final json = await _send('PUT', '/api/topics/$id', body: {'body': body});
    return Topic.fromJson(json);
  }

  /// DELETE /api/topics/{id} - delete your own topic.
  Future<void> deleteTopic(int id) async {
    await _send('DELETE', '/api/topics/$id');
  }

  /// POST /api/comments/type/topic/{id} - comment on a topic.
  Future<Comment> addComment(int topicId, String body) async {
    final json = await _send('POST', '/api/comments/type/topic/$topicId', body: {'body': body, 'status': contentStatus});
    return Comment.fromJson(json);
  }

  /// POST /api/comments/type/comment/{id} - reply to a comment.
  Future<Comment> addReply(int commentId, String body) async {
    final json = await _send('POST', '/api/comments/type/comment/$commentId', body: {'body': body, 'status': contentStatus});
    return Comment.fromJson(json);
  }

  /// PUT /api/comments/{id} - edit your own comment.
  Future<Comment> updateComment(int id, {required String body}) async {
    final json = await _send('PUT', '/api/comments/$id', body: {'body': body});
    return Comment.fromJson(json);
  }

  /// DELETE /api/comments/{id} - delete your own comment (its replies go too).
  Future<void> deleteComment(int id) async {
    await _send('DELETE', '/api/comments/$id');
  }

  /// POST /api/votes/up/{type}/{id} or /api/votes/down/{type}/{id}, where
  /// [type] is `topic` or `comment`. No body is needed. The answer's `points`
  /// is the content's new total score (an integer), not your own vote;
  /// repeating a vote changes nothing.
  Future<VoteResult> vote(String type, int id, {required bool up}) async {
    final json = await _send('POST', '/api/votes/${up ? 'up' : 'down'}/$type/$id');
    return VoteResult.fromJson(json);
  }

  /// DELETE /api/votes/{type}/{id} - take your vote back. Taking back a vote
  /// you never cast is harmless.
  Future<void> removeVote(String type, int id) async {
    await _send('DELETE', '/api/votes/$type/$id');
  }

  /// POST /api/reports/type/{type}/{id} - report a `topic` or `comment`.
  /// ([reason] is one of [reportTypes].)
  Future<void> report(String type, int id, {required String reason, String? details}) async {
    await _send('POST', '/api/reports/type/$type/$id', body: {
      'type': reason,
      if (details != null && details.isNotEmpty) 'body': details,
    });
  }

  // ---------------------------------------------------------------- plumbing

  /// Every row of a list, page by page. A list answers
  /// `{"data": [...], "total": 42, "page": 1, "per_page": 25}`.
  Future<List<Map<String, dynamic>>> _allRows(String path) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 1;; page++) {
      final json = await _send('GET', path, query: {'page': '$page', 'per_page': '$_perPage'}, authenticated: false);
      final data = json['data'] as List? ?? const [];
      rows.addAll(data.cast<Map<String, dynamic>>());
      if (data.isEmpty || rows.length >= (json['total'] as num? ?? 0)) return rows;
    }
  }

  /// Sends one request and returns the decoded JSON. Pass
  /// `authenticated: false` for calls that do not carry the Bearer token
  /// (reads, login and register).
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, Object?>? body,
    bool authenticated = true,
  }) async {
    // [path] may already hold %XX escapes (see Uri.encodeComponent for slugs).
    // Uri.https would encode the % again, so parse it and only add the query.
    final uri = Uri.parse('https://$host$path').replace(queryParameters: {...query, 'apikey': apiKey});
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers.addAll({if (authenticated && token != null) 'Authorization': 'Bearer $token'});
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request));
    } catch (e) {
      throw ApiException(0, 'Could not reach $host. Check your connection and try again.');
    }

    Object? decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _errorMessage(response.statusCode, decoded);
      final error = ApiException(response.statusCode, message);
      // A 401 about the login token, on a call that sent it: the session is over.
      if (authenticated && token != null && response.statusCode == 401 && !error.keyRejected) {
        token = null;
        onSessionExpired?.call();
        throw ApiException(401, message, sessionEnded: true);
      }
      throw error;
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  /// Errors arrive as `{"message": "..."}`; fall back to showing whatever
  /// came back.
  String _errorMessage(int status, Object? decoded) {
    if (decoded is Map) {
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) return message;
      if (decoded['errors'] != null) return '${decoded['errors']}';
    }
    return 'Something went wrong. Please try again.';
  }
}
