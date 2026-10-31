/// The whole Forums API client. Every network call in the app is in this file.
///
/// Docs: https://forums.simpleapi.dev/docs
///
/// Two rules apply to every request:
///  * the developer key goes in the `apikey` QUERY parameter (never a header);
///  * calls that write data also send `Authorization: Bearer <token>`, where
///    the token comes from [ForumsApi.register] / [ForumsApi.login]. The
///    client never sends an author: the API uses the logged-in user.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Thrown for any non-2xx answer. [message] is the API's own `message` when it
/// sent one, e.g. "The selected status is invalid.".
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Values the API accepts (it answers 422 for anything else). The docs do not
/// list them; they were found by trying the API (see tool/live_check).
const contentStatus = 'Active';
const topicType = 'Post';

/// Whether a forum or topic created with [title] can be read back.
///
/// The API builds slugs from titles (lowercase, spaces become `_`, anything
/// else is kept) and then looks them up WITHOUT url-decoding the path. A slug
/// that must be percent-encoded to travel in a URL (accents, emoji, `?`, `%`,
/// `/`, `#`...) therefore answers 404 forever. This guard lets the UI refuse
/// such titles up front.
bool titleIsLookupSafe(String title) {
  final slug = title.trim().toLowerCase().replaceAll(' ', '_');
  // A `/` would survive encoding but split the path into two segments.
  return slug.isNotEmpty && !slug.contains('/') && Uri.https('x', '/$slug').path == '/$slug';
}

const unsafeTitleMessage =
    'Please use plain letters, numbers and simple punctuation in the title. '
    'The API cannot look up titles with accents, emoji or ? % # / characters.';

/// Report types the API accepted when tried: "Offensive" and "Other".
const reportTypes = ['Offensive', 'Other'];

class ForumsApi {
  ForumsApi({
    required this.apiKey,
    this.token,
    http.Client? client,
    this.host = 'forums.simpleapi.dev',
  }) : _http = client ?? http.Client();

  final String apiKey;
  final String host;

  /// Set after [login] / [register]; sent as the Bearer token.
  String? token;

  final http.Client _http;

  // ---------------------------------------------------------------- reading

  /// GET /api/forums - all forums of this key (an empty list at first).
  Future<List<Forum>> listForums() async {
    final json = await _send('GET', '/api/forums');
    return [for (final f in json['_list'] as List) Forum.fromJson(f as Map<String, dynamic>)];
  }

  /// GET /api/forums/{slug}/topics - topics in a forum.
  Future<List<Topic>> listTopics(String forumSlug) async {
    final json = await _send('GET', '/api/forums/$forumSlug/topics');
    return [for (final t in json['_list'] as List) Topic.fromJson(t as Map<String, dynamic>)];
  }

  /// GET /api/topics/{slug} - one topic with its whole comment tree
  /// (replies nested under `comments`). Looked up by slug, not by id.
  Future<Topic> getTopic(String topicSlug) async {
    final json = await _send('GET', '/api/topics/$topicSlug');
    return Topic.fromJson(json);
  }

  // ------------------------------------------------------------------ users

  /// POST /api/users/register - create a user that belongs to this key.
  /// Answers 200 with a token, or 202 (no token) when the email is the one the
  /// key belongs to and a confirmation code was emailed instead.
  Future<AuthResult> register({required String name, required String email, required String password}) async {
    final json = await _send('POST', '/api/users/register', body: {'name': name, 'email': email, 'password': password});
    return _authResult(json);
  }

  /// POST /api/users/login - returns the user and a token.
  Future<AuthResult> login({required String email, required String password}) async {
    final json = await _send('POST', '/api/users/login', body: {'email': email, 'password': password});
    return _authResult(json);
  }

  /// POST /api/users/logout - invalidates the current token.
  Future<void> logout() async {
    await _send('POST', '/api/users/logout', body: const {});
    token = null;
  }

  AuthResult _authResult(Map<String, dynamic> json) {
    final t = json['token'];
    if (t is String && t.isNotEmpty) {
      token = t;
      return AuthResult(token: t, id: '${json['id'] ?? ''}', name: '${json['name'] ?? ''}');
    }
    return AuthResult(message: '${json['message'] ?? 'Confirmation required.'}');
  }

  // ---------------------------------------------------------------- writing
  // Everything below needs a logged-in user (Bearer token).

  /// POST /api/forums - create a forum. Basic keys are limited to 3 forums.
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
  /// The docs call `body` optional but the API answers 422 without it.
  Future<Topic> createTopic(int forumId, {required String title, required String body}) async {
    final json = await _send('POST', '/api/forums/$forumId/topics', body: {
      'title': title,
      'status': contentStatus,
      'type': topicType,
      'body': body,
    });
    return Topic.fromJson(json);
  }

  /// PUT /api/topics/{id} - edit the text of your own topic.
  Future<Topic> updateTopic(int id, {required String body}) async {
    final json = await _send('PUT', '/api/topics/$id', body: {'body': body, 'status': contentStatus});
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
    final json = await _send('PUT', '/api/comments/$id', body: {'body': body, 'status': contentStatus});
    return Comment.fromJson(json);
  }

  /// DELETE /api/comments/{id} - delete your own comment (its replies go too).
  Future<void> deleteComment(int id) async {
    await _send('DELETE', '/api/comments/$id');
  }

  /// POST /api/votes/up/{type}/{id} or /api/votes/down/{type}/{id}, where
  /// [type] is `topic` or `comment`. The API insists on a JSON body, so an
  /// empty object is sent. The answer's `points` is the content's new total
  /// score (not your own vote); repeating a vote changes nothing and there is
  /// no call to take a vote back.
  Future<VoteResult> vote(String type, int id, {required bool up}) async {
    final json = await _send('POST', '/api/votes/${up ? 'up' : 'down'}/$type/$id', body: const {});
    return VoteResult.fromJson(json);
  }

  /// POST /api/reports/type/{type}/{id} - report a `topic` or `comment`.
  /// ([reason] is one of [reportTypes].) This is the route that works; the
  /// Swagger page documents /api/{type}/{id}/reports, which answers 404.
  Future<void> report(String type, int id, {required String reason, String? details}) async {
    await _send('POST', '/api/reports/type/$type/$id', body: {
      'type': reason,
      if (details != null && details.isNotEmpty) 'body': details,
    });
  }

  // ---------------------------------------------------------------- plumbing

  /// Sends one request and returns the decoded JSON. A JSON array is wrapped
  /// as `{'_list': [...]}` so every caller gets a Map.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.https(host, path, {...query, 'apikey': apiKey});
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'});
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request));
    } catch (e) {
      throw ApiException(0, 'Could not reach $host ($e)');
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
      throw ApiException(response.statusCode, _errorMessage(response.statusCode, decoded));
    }
    if (decoded is List) return {'_list': decoded};
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
    return 'Request failed (HTTP $status).';
  }
}
