// Live check of the Forums API v2 against the real service.
//
//     SIMPLEAPI_KEY=<your key> dart run tool/live_check/live_check.dart [out.md] [--orphan-report]
//
// --orphan-report also runs the one check that leaves a stuck row behind on
// the key (deleting a report after its comment is gone answers 500, and the
// report can then never be removed). Off by default.
//
// The key is read from the environment and is never written anywhere. Test
// users get random emails/passwords generated at run time. Requests are paced
// at about one per second and retried with a back-off on 429. Everything the
// run creates is deleted at the end (and the leftovers are listed).
//
// Output: a markdown table of every check (expected per docs, actual,
// PASS/FAIL) plus notes, printed and written to [out.md] (default
// tool/live_check/results.md). Bodies are shortened and tokens/emails are
// redacted before they are recorded.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:forums_client_flutter/forums_api.dart';
import 'package:forums_client_flutter/models.dart';
import 'package:http/http.dart' as http;

const host = 'forums.simpleapi.dev';
final key = Platform.environment['SIMPLEAPI_KEY'] ?? '';
final rnd = Random.secure();
final client = http.Client();

class Resp {
  Resp(this.status, this.raw, this.json);
  final int status;
  final String raw;
  final Object? json;
  Map<String, dynamic> get map => json is Map<String, dynamic> ? json as Map<String, dynamic> : {};
  List get list => json is List ? json as List : [];
  dynamic operator [](String k) => map[k];
  String get message => '${map['message'] ?? ''}';
}

int requests = 0;
int preexistingForums = 0;
int throttled = 0;
final notes = <String>[];

String randomString(int n) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(n, (_) => chars[rnd.nextInt(chars.length)]).join();
}

/// One paced request. [body] is JSON-encoded unless [rawBody] is given.
Future<Resp> call(
  String method,
  String path, {
  String? token,
  Object? body,
  String? rawBody,
  Map<String, String> query = const {},
  bool withKey = true,
  String? keyOverride,
  Map<String, String> headers = const {},
  bool rawPath = false,
}) async {
  for (var attempt = 0; attempt < 6; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    // [rawPath]: [path] is already encoded exactly as a client would send it.
    final uri = rawPath
        ? Uri.parse('https://$host$path?apikey=${keyOverride ?? key}')
        : Uri.https(host, path, {...query, if (withKey) 'apikey': keyOverride ?? key});
    final req = http.Request(method, uri)..headers['Accept'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.headers.addAll(headers);
    if (rawBody != null) {
      req.body = rawBody;
    } else if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    requests++;
    final r = await http.Response.fromStream(await client.send(req));
    if (r.statusCode == 429) {
      throttled++;
      final wait = int.tryParse(r.headers['retry-after'] ?? '') ?? (5 << attempt);
      stdout.writeln('  429 on $method $path, waiting ${wait}s');
      await Future<void>.delayed(Duration(seconds: wait));
      continue;
    }
    Object? j;
    try {
      j = r.body.trim().isEmpty ? null : jsonDecode(r.body);
    } on FormatException {
      j = null;
    }
    final resp = Resp(r.statusCode, r.body, j);
    scanForBodyIssues(method, path, resp);
    return resp;
  }
  return Resp(429, 'still throttled after retries', null);
}

/// Records anything that looks like the "body field" / Carbon date problems a
/// prior team note mentioned.
void scanForBodyIssues(String method, String path, Resp r) {
  final low = r.raw.toLowerCase();
  if (low.contains('carbon') ||
      low.contains('trailing data') ||
      low.contains('could not be parsed') ||
      low.contains('unexpected data found') ||
      (r.status >= 500) ||
      (r.status >= 400 && low.contains('"body') && low.contains('message'))) {
    notes.add('`$method $path` -> ${r.status}: ${redact(r.raw, 160)}');
  }
}

final _emailRe = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
final _tokenRe = RegExp(r'"token":"[^"]*"');

String redact(String s, [int max = 110]) {
  var t = s.replaceAll(_tokenRe, '"token":"<redacted>"').replaceAll(_emailRe, '<email>');
  if (key.isNotEmpty) t = t.replaceAll(key, '<key>');
  t = t.replaceAll('\n', ' ').replaceAll('|', '\\|');
  return t.length > max ? '${t.substring(0, max)}...' : t;
}

class Check {
  Check(this.area, this.what, this.expected, this.actual, this.pass);
  final String area, what, expected, actual;
  final bool pass;
}

final checks = <Check>[];

Resp record(String area, String what, String expected, Resp r, bool Function(Resp) ok) {
  final pass = ok(r);
  checks.add(Check(area, what, expected, 'HTTP ${r.status} ${redact(r.raw)}', pass));
  stdout.writeln('${pass ? 'PASS' : 'FAIL'}  [$area] $what -> ${r.status}');
  return r;
}

bool st(Resp r, int s) => r.status == s;
bool is4xx(Resp r) => r.status >= 400 && r.status < 500;

// Everything created, for the cleanup at the end.
final cleanup = <({String kind, int id, String owner})>[];
void track(String kind, Resp r, String owner) {
  final id = r.map['id'];
  if (id is int) cleanup.add((kind: kind, id: id, owner: owner));
}

/// Test users (owner label -> credentials), so cleanup can log in afresh
/// instead of relying on tokens that a logout test may have invalidated.
final creds = <String, ({String email, String pw})>{};

Future<void> main(List<String> args) async {
  if (key.isEmpty) {
    stderr.writeln('Set SIMPLEAPI_KEY first.');
    exit(2);
  }
  final paths = args.where((a) => !a.startsWith('--')).toList();
  final out = paths.isNotEmpty ? paths.first : 'tool/live_check/results.md';
  final tag = randomString(8);
  String email(String who) => 'simpleapi-sample-apps+$who$tag@agentmail.to';
  final pwA = 'Pw-${randomString(14)}';
  final pwB = 'Pw-${randomString(14)}';
  String? tokenA, tokenB;
  var idA = 0, idB = 0;

  try {
    // ------------------------------------------------------------- apikey
    var r = record('apikey', 'GET /forums without apikey', '401', await call('GET', '/api/forums', withKey: false), (r) => st(r, 401));
    r = record('apikey', 'GET /forums with unknown apikey', '401', await call('GET', '/api/forums', keyOverride: '00000000-0000-0000-0000-000000000000'), (r) => st(r, 401));
    r = record('apikey', 'GET /forums with malformed apikey', '401', await call('GET', '/api/forums', keyOverride: 'not-a-key'), (r) => st(r, 401));
    r = r = record('apikey', 'apikey sent as a header only (docs say query)', 'docs only describe the query form; 200 or 401', await call('GET', '/api/forums', withKey: false, headers: {'apikey': key}), (r) => st(r, 200) || st(r, 401));
    if (r.status == 200) notes.add('A key sent only as an `apikey` HTTP header is accepted too, although the docs describe only the query parameter.');
    r = record('apikey', 'POST /users/login with bad apikey', '401', await call('POST', '/api/users/login', keyOverride: 'nope', body: {'email': email('x'), 'password': 'x'}), (r) => st(r, 401));

    // ------------------------------------------------------------- empty state
    r = record('forums', 'GET /forums on a fresh key', '200 + list (empty on a fresh key)', await call('GET', '/api/forums'), (r) => st(r, 200) && r.json is List);
    if (r.list.isNotEmpty) notes.add('The key already had ${r.list.length} forum(s) before the run; they are left alone.');
    preexistingForums = r.list.length;

    // ------------------------------------------------------------- users
    r = record('users', 'register user A', '200 + token/id', await call('POST', '/api/users/register', body: {'name': 'Sample A', 'email': email('a'), 'password': pwA}), (r) => st(r, 200) && r['token'] is String && r['id'] is int);
    tokenA = r['token'] as String?;
    idA = (r['id'] as int?) ?? 0;
    if (idA > 0) cleanup.add((kind: 'user', id: idA, owner: 'A'));
    creds['A'] = (email: email('a'), pw: pwA);

    r = record('users', 'register user B', '200 + token/id', await call('POST', '/api/users/register', body: {'name': 'Sample B', 'email': email('b'), 'password': pwB}), (r) => st(r, 200) && r['token'] is String);
    tokenB = r['token'] as String?;
    idB = (r['id'] as int?) ?? 0;
    if (idB > 0) cleanup.add((kind: 'user', id: idB, owner: 'B'));
    creds['B'] = (email: email('b'), pw: pwB);

    r = record('users', 'register duplicate email', '4xx (docs silent; 409/422 expected)', await call('POST', '/api/users/register', body: {'name': 'Dup', 'email': email('a'), 'password': pwA}), is4xx);
    record('users', 'register bad email', '422', await call('POST', '/api/users/register', body: {'name': 'Bad', 'email': 'not-an-email', 'password': pwA}), (r) => st(r, 422));
    r = record('users', 'register short password (3 chars)', '4xx (docs silent about a minimum)', await call('POST', '/api/users/register', body: {'name': 'Short', 'email': email('s'), 'password': 'abc'}), is4xx);
    if (r.status == 200 && r['id'] is int) {
      // The API accepted it: remember to delete that user again.
      cleanup.add((kind: 'user', id: r['id'] as int, owner: 'S'));
      creds['S'] = (email: email('s'), pw: 'abc');
    }
    record('users', 'register without name', '422', await call('POST', '/api/users/register', body: {'email': email('n'), 'password': pwA}), (r) => st(r, 422));
    record('users', 'register with empty body', '422', await call('POST', '/api/users/register', body: <String, Object?>{}), (r) => st(r, 422));
    record('users', 'register with non-JSON body', '4xx', await call('POST', '/api/users/register', rawBody: 'name=a&email=b', headers: {'Content-Type': 'application/x-www-form-urlencoded'}), is4xx);

    r = record('users', 'login right credentials', '200 + token', await call('POST', '/api/users/login', body: {'email': email('a'), 'password': pwA}), (r) => st(r, 200) && r['token'] is String);
    final oldTokenA = tokenA;
    tokenA = (r['token'] as String?) ?? tokenA;
    record('users', 'login wrong password', '404 (per docs)', await call('POST', '/api/users/login', body: {'email': email('a'), 'password': 'wrong-${randomString(6)}'}), (r) => st(r, 404));
    record('users', 'login unknown email', '404 (per docs)', await call('POST', '/api/users/login', body: {'email': email('nobody'), 'password': pwA}), (r) => st(r, 404));
    record('users', 'login without password', '422', await call('POST', '/api/users/login', body: {'email': email('a')}), (r) => st(r, 422));
    record('users', 'GET /users/me with token', '200 + user', await call('GET', '/api/users/me', token: tokenA), (r) => st(r, 200) && r['id'] == idA);
    if (checks.last.actual.contains('"token"')) {
      notes.add('`GET /api/users/me` returns the caller\'s own bearer token in the response body (not needed by clients).');
    }
    record('users', 'GET /users/me without token', '401', await call('GET', '/api/users/me'), (r) => st(r, 401));
    record('users', 'GET /users/me with garbage token', '401', await call('GET', '/api/users/me', token: 'garbage'), (r) => st(r, 401));
    record('users', 'GET /users (admin only) as normal user', '403', await call('GET', '/api/users', token: tokenA), (r) => st(r, 403));
    r = record('users', 'token from register after a second login (single active token?)', 'docs silent: 200 (tokens independent) or 401 (replaced)', await call('GET', '/api/users/me', token: oldTokenA), (r) => st(r, 200) || st(r, 401));
    if (r.status == 401) notes.add('Logging in again replaces the user\'s previous token: the token returned by register stops working (401) once login has been called. Only one token per user is live at a time.');

    // ------------------------------------------------------------- forums
    record('forums', 'create forum without token', '401', await call('POST', '/api/forums', body: {'title': 'x', 'status': 'Active'}), (r) => st(r, 401));
    record('forums', 'create forum with status "published"', '422 (docs do not list valid statuses)', await call('POST', '/api/forums', token: tokenA, body: {'title': 'x', 'status': 'published'}), (r) => st(r, 422));
    record('forums', 'create forum without title', '422', await call('POST', '/api/forums', token: tokenA, body: {'status': 'Active'}), (r) => st(r, 422));
    record('forums', 'create forum with empty title', '422', await call('POST', '/api/forums', token: tokenA, body: {'title': '', 'status': 'Active'}), (r) => st(r, 422));
    r = record('forums', 'create forum 1 as A (body omitted)', '200 + id/slug', await call('POST', '/api/forums', token: tokenA, body: {'title': 'Live check $tag', 'status': 'Active'}), (r) => st(r, 200) && r['id'] is int && r['slug'] is String);
    track('forum', r, 'A');
    final forumId = (r['id'] as int?) ?? 0;
    final forumSlug = '${r['slug']}';
    r = record('forums', 'create forum 2 with description and an emoji title', '200', await call('POST', '/api/forums', token: tokenA, body: {'title': 'Second $tag \u{1F600}', 'body': 'Description', 'status': 'Active'}), (r) => st(r, 200));
    track('forum', r, 'A');
    final forum2 = (r['id'] as int?) ?? 0;
    r = record('forums', 'create forum 3', '200', await call('POST', '/api/forums', token: tokenA, body: {'title': 'Third $tag', 'status': 'Active'}), (r) => st(r, 200));
    track('forum', r, 'A');
    final forum3 = (r['id'] as int?) ?? 0;
    record('forums', 'list forums', '200 + list incl. the new ones', await call('GET', '/api/forums'), (r) => st(r, 200) && r.list.length >= preexistingForums + 3);
    record('forums', 'get forum by slug', '200', await call('GET', '/api/forums/$forumSlug'), (r) => st(r, 200) && r['id'] == forumId);
    record('forums', 'get forum by numeric id', '200 or 404 (docs name the param slug)', await call('GET', '/api/forums/$forumId'), (r) => st(r, 200) || st(r, 404));
    record('forums', 'get unknown forum', '404', await call('GET', '/api/forums/no_such_forum_$tag'), (r) => st(r, 404));
    record('forums', 'list topics of an empty forum', '200 + []', await call('GET', '/api/forums/$forumSlug/topics'), (r) => st(r, 200) && r.list.isEmpty);
    record('forums', 'list topics of unknown forum', '404', await call('GET', '/api/forums/no_such_forum_$tag/topics'), (r) => st(r, 404));
    record('forums', 'delete forum 3 as non-author B', '403', await call('DELETE', '/api/forums/$forum3', token: tokenB), (r) => st(r, 403));
    record('forums', 'documented route DELETE /forum/{id} (singular)', '200 per docs', await call('DELETE', '/api/forum/$forum3', token: tokenA), (r) => st(r, 200));
    record('forums', 'DELETE /forums/{id} (plural, used by the app) as author', '200', await call('DELETE', '/api/forums/$forum3', token: tokenA), (r) => st(r, 200));
    record('forums', 'update forum 2 as non-author B', '403', await call('PUT', '/api/forums/$forum2', token: tokenB, body: {'body': 'hijack', 'status': 'Active'}), (r) => st(r, 403));
    record('forums', 'update forum 2 as author', '200', await call('PUT', '/api/forums/$forum2', token: tokenA, body: {'body': 'Edited description', 'status': 'Active'}), (r) => st(r, 200));

    // Slugs: the API never url-decodes path segments (see README / REPORT).
    for (final t in ['Bob\'s (best) forum! $tag', 'Caf\u00e9 au lait $tag', 'Smile \u{1F600} $tag', 'Why? $tag', '100% $tag']) {
      final created = await call('POST', '/api/forums', token: tokenA, body: {'title': t, 'status': 'Active'});
      track('forum', created, 'A');
      if (created['id'] is! int) {
        checks.add(Check('slugs', 'create forum titled "${redact(t, 40)}"', '200', 'HTTP ${created.status} ${redact(created.raw)}', false));
        continue;
      }
      final slug = '${created['slug']}';
      final uriPath = Uri.https(host, '/api/forums/$slug/topics', {'apikey': key}); // encoded the way a client library does
      final read = await call('GET', uriPath.path.substring(0), query: const {}, rawPath: true);
      final safe = titleIsLookupSafe(t);
      checks.add(Check('slugs', 'forum titled "${redact(t, 40)}" can be read back by its slug', safe ? '200 (slug is URL-safe)' : '200 per docs; the app refuses this title', 'create HTTP ${created.status}, slug "${redact(slug, 40)}", GET HTTP ${read.status}; app guard says ${safe ? 'safe' : 'unsafe'}', read.status == 200 || !safe));
      if (read.status != 200) notes.add('Forum slug `${redact(slug, 40)}` cannot be read (HTTP ${read.status}): the API does not url-decode path segments.');
      await call('DELETE', '/api/forums/${created['id']}', token: tokenA); // keep the number of live forums low
    }

    // Docs: "limit of 3 forums per basic developer account". Keep creating
    // (up to 12 more) until the API says no; the extra forums are deleted at once.
    final extra = <int>[];
    var capResult = 'no limit reached after 12 extra forums';
    var capHit = false;
    var existing = 0;
    for (var n = 1; n <= 12 && !capHit; n++) {
      final rr = await call('POST', '/api/forums', token: tokenA, body: {'title': 'Cap probe $n $tag', 'status': 'Active'});
      if (rr.status == 200 && rr['id'] is int) {
        extra.add(rr['id'] as int);
        cleanup.add((kind: 'forum', id: rr['id'] as int, owner: 'A'));
      } else {
        capHit = true;
        existing = (await call('GET', '/api/forums')).list.length;
        capResult = 'rejected with HTTP ${rr.status} ${redact(rr.raw)} when the key already had $existing forums';
      }
    }
    checks.add(Check('forums', 'forum limit ("3 per basic developer account")', 'a forum beyond the 3rd is rejected', capResult, capHit && existing <= 3));
    notes.add('Forum limit probe: $capResult.');
    for (final id in extra) {
      await call('DELETE', '/api/forums/$id', token: tokenA);
    }

    // ------------------------------------------------------------- topics
    record('topics', 'create topic without token', '401', await call('POST', '/api/forums/$forumId/topics', body: {'title': 't', 'status': 'Active', 'type': 'Post'}), (r) => st(r, 401));
    r = record('topics', 'create topic as A', '200 + id/slug', await call('POST', '/api/forums/$forumId/topics', token: tokenA, body: {'title': 'Topic one $tag', 'body': 'First post', 'status': 'Active', 'type': 'Post'}), (r) => st(r, 200) && r['id'] is int);
    track('topic', r, 'A');
    final topicId = (r['id'] as int?) ?? 0;
    final topicSlug = '${r['slug']}';
    r = record('topics', 'create a second topic with the same title in the same forum', 'docs silent: 200 (distinct slug) or 4xx', await call('POST', '/api/forums/$forumId/topics', token: tokenA, body: {'title': 'Topic one $tag', 'body': 'Same title again', 'status': 'Active', 'type': 'Post'}), (r) => st(r, 200) || is4xx(r));
    if (r.status == 200) {
      track('topic', r, 'A');
      notes.add('Duplicate topic title in one forum: slug "${redact('${r['slug']}', 40)}" (first one is "$topicSlug").');
    }
    record('topics', 'create topic without title', '422', await call('POST', '/api/forums/$forumId/topics', token: tokenA, body: {'status': 'Active', 'type': 'Post'}), (r) => st(r, 422));
    record('topics', 'create topic with bad type "Poem"', '422', await call('POST', '/api/forums/$forumId/topics', token: tokenA, body: {'title': 't', 'status': 'Active', 'type': 'Poem'}), (r) => st(r, 422));
    record('topics', 'create topic with bad status', '422', await call('POST', '/api/forums/$forumId/topics', token: tokenA, body: {'title': 't', 'status': 'nope', 'type': 'Post'}), (r) => st(r, 422));
    r = record('topics', 'create topic with empty body (docs: body is optional)', '200 per docs', await call('POST', '/api/forums/$forumId/topics', token: tokenA, body: {'title': 'No text $tag', 'body': '', 'status': 'Active', 'type': 'Post'}), (r) => st(r, 200));
    track('topic', r, 'A');
    r = record('topics', 'create topic with no body key (docs: body is optional)', '200 per docs', await call('POST', '/api/forums/$forumId/topics', token: tokenA, body: {'title': 'No body key $tag', 'status': 'Active', 'type': 'Post'}), (r) => st(r, 200));
    track('topic', r, 'A');
    record('topics', 'create topic in unknown forum', '404', await call('POST', '/api/forums/99999999/topics', token: tokenA, body: {'title': 't', 'status': 'Active', 'type': 'Post'}), (r) => st(r, 404));
    r = record('topics', 'create topic with a 5000 char body', '200 or 422', await call('POST', '/api/forums/$forumId/topics', token: tokenA, body: {'title': 'Long $tag', 'body': 'x' * 5000, 'status': 'Active', 'type': 'Post'}), (r) => st(r, 200) || st(r, 422));
    if (r.status == 200) track('topic', r, 'A');
    record('topics', 'list topics in forum', '200 + the topic created above', await call('GET', '/api/forums/$forumSlug/topics'), (r) => st(r, 200) && r.list.isNotEmpty);
    record('topics', 'get topic by slug (with comments key)', '200 + comments list', await call('GET', '/api/topics/$topicSlug'), (r) => st(r, 200) && r['comments'] is List);
    record('topics', 'get topic by numeric id', '200 or 404 (docs name the param id in one place, slug in the path)', await call('GET', '/api/topics/$topicId'), (r) => st(r, 200) || st(r, 404));
    record('topics', 'get unknown topic', '404', await call('GET', '/api/topics/no_such_topic_$tag'), (r) => st(r, 404));
    record('topics', 'search topics', '200', await call('GET', '/api/topics/search', query: {'phrase': 'Topic one'}), (r) => st(r, 200));
    record('topics', 'search topics without phrase', '4xx (phrase is required in docs)', await call('GET', '/api/topics/search'), is4xx);
    record('topics', 'edit own topic', '200 + new body', await call('PUT', '/api/topics/$topicId', token: tokenA, body: {'body': 'Edited post', 'status': 'Active'}), (r) => st(r, 200) && r['body'] == 'Edited post');
    record('topics', 'edit topic as non-author B', '403', await call('PUT', '/api/topics/$topicId', token: tokenB, body: {'body': 'hijacked', 'status': 'Active'}), (r) => st(r, 403));
    record('topics', 'edit topic without token', '401', await call('PUT', '/api/topics/$topicId', body: {'body': 'x', 'status': 'Active'}), (r) => st(r, 401));
    record('topics', 'edit topic with empty body (body is required in docs)', '422', await call('PUT', '/api/topics/$topicId', token: tokenA, body: {'body': '', 'status': 'Active'}), (r) => st(r, 422));
    record('topics', 'edit topic without status', '422', await call('PUT', '/api/topics/$topicId', token: tokenA, body: {'body': 'x'}), (r) => st(r, 422));
    record('topics', 'edit unknown topic', '404', await call('PUT', '/api/topics/99999999', token: tokenA, body: {'body': 'x', 'status': 'Active'}), (r) => st(r, 404));
    record('topics', 'get topic after edit shows new body', '200', await call('GET', '/api/topics/$topicSlug'), (r) => st(r, 200) && r['body'] == 'Edited post');

    // ------------------------------------------------------------- comments
    record('comments', 'create comment without token', '401', await call('POST', '/api/comments/type/topic/$topicId', body: {'body': 'hi', 'status': 'Active'}), (r) => st(r, 401));
    r = record('comments', 'create comment on topic as A', '200 + id', await call('POST', '/api/comments/type/topic/$topicId', token: tokenA, body: {'body': 'Top level', 'status': 'Active'}), (r) => st(r, 200) && r['id'] is int);
    track('comment', r, 'A');
    final c1 = (r['id'] as int?) ?? 0;
    record('comments', 'create comment with empty body', '422', await call('POST', '/api/comments/type/topic/$topicId', token: tokenA, body: {'body': '', 'status': 'Active'}), (r) => st(r, 422));
    record('comments', 'create comment without body key', '422', await call('POST', '/api/comments/type/topic/$topicId', token: tokenA, body: {'status': 'Active'}), (r) => st(r, 422));
    record('comments', 'create comment with whitespace-only body', '422', await call('POST', '/api/comments/type/topic/$topicId', token: tokenA, body: {'body': '   ', 'status': 'Active'}), (r) => st(r, 422));
    record('comments', 'create comment without status', '422 (status is required in docs)', await call('POST', '/api/comments/type/topic/$topicId', token: tokenA, body: {'body': 'no status'}), (r) => st(r, 422));
    record('comments', 'create comment on unknown topic', '404', await call('POST', '/api/comments/type/topic/99999999', token: tokenA, body: {'body': 'x', 'status': 'Active'}), (r) => st(r, 404));
    record('comments', 'create comment with bad {type}', '4xx', await call('POST', '/api/comments/type/forum/$forumId', token: tokenA, body: {'body': 'x', 'status': 'Active'}), is4xx);
    r = record('comments', 'reply to a comment as B', '200 + commentable_id = parent', await call('POST', '/api/comments/type/comment/$c1', token: tokenB, body: {'body': 'A reply from B', 'status': 'Active'}), (r) => st(r, 200) && r['commentable_id'] == c1);
    track('comment', r, 'B');
    final c2 = (r['id'] as int?) ?? 0;
    record('comments', 'reply to unknown comment', '404', await call('POST', '/api/comments/type/comment/99999999', token: tokenB, body: {'body': 'x', 'status': 'Active'}), (r) => st(r, 404));

    // Deep nesting: 12 levels below c1.
    var parent = c2;
    var depthOk = 0;
    for (var i = 3; i <= 12; i++) {
      final rr = await call('POST', '/api/comments/type/comment/$parent', token: i.isEven ? tokenA : tokenB, body: {'body': 'Level $i', 'status': 'Active'});
      if (rr.status != 200) {
        checks.add(Check('comments', 'deep reply at level $i', '200', 'HTTP ${rr.status} ${redact(rr.raw)}', false));
        break;
      }
      depthOk = i;
      parent = rr['id'] as int;
    }
    checks.add(Check('comments', 'deep reply nesting up to level 12', '200 at each level', 'reached level $depthOk', depthOk == 12));
    record('comments', 'GET topic returns the nested tree 12 levels deep', '200, nesting preserved', await call('GET', '/api/topics/$topicSlug'), (r) {
      var d = 0;
      var level = r['comments'];
      while (level is List && level.isNotEmpty) {
        d++;
        level = (level.first as Map)['comments'];
      }
      notes.add('Topic GET nested comment depth reported: $d');
      return d == 12;
    });
    record('comments', 'GET /topics/{id}/comments', '200 + list', await call('GET', '/api/topics/$topicId/comments'), (r) => st(r, 200) && r.list.isNotEmpty);
    record('comments', 'GET /comments/{id}', '200', await call('GET', '/api/comments/$c1'), (r) => st(r, 200) && r['id'] == c1);
    record('comments', 'GET unknown comment', '404', await call('GET', '/api/comments/99999999'), (r) => st(r, 404));
    record('comments', 'search comments, one-word phrase', '200 + matches', await call('GET', '/api/comments/search', query: {'phrase': 'Top'}), (r) => st(r, 200) && r.list.isNotEmpty);
    record('comments', 'search comments, phrase with a space ("Top level")', '200 + matches', await call('GET', '/api/comments/search', query: {'phrase': 'Top level'}), (r) => st(r, 200));
    record('comments', 'search comments, second word only ("level")', '200 + matches', await call('GET', '/api/comments/search', query: {'phrase': 'level'}), (r) => st(r, 200));
    record('comments', 'search comments, no match', 'docs silent: 200 [] or 404', await call('GET', '/api/comments/search', query: {'phrase': 'zzzznomatch$tag'}), (r) => st(r, 200) || st(r, 404));
    record('comments', 'search comments without phrase', '4xx (phrase is required in docs)', await call('GET', '/api/comments/search'), is4xx);
    record('comments', 'edit own comment', '200 + new body', await call('PUT', '/api/comments/$c1', token: tokenA, body: {'body': 'Top level (edited)', 'status': 'Active'}), (r) => st(r, 200) && r['body'] == 'Top level (edited)');
    record('comments', 'edit comment as non-author B', '403', await call('PUT', '/api/comments/$c1', token: tokenB, body: {'body': 'hijack', 'status': 'Active'}), (r) => st(r, 403));
    record('comments', 'edit comment with empty body', '422', await call('PUT', '/api/comments/$c1', token: tokenA, body: {'body': '', 'status': 'Active'}), (r) => st(r, 422));
    record('comments', 'edit unknown comment', '404', await call('PUT', '/api/comments/99999999', token: tokenA, body: {'body': 'x', 'status': 'Active'}), (r) => st(r, 404));
    record('comments', 'delete comment as non-author B', '403', await call('DELETE', '/api/comments/$c1', token: tokenB), (r) => st(r, 403));
    record('comments', 'delete comment without token', '401', await call('DELETE', '/api/comments/$c1'), (r) => st(r, 401));

    // ------------------------------------------------------------- votes
    record('votes', 'upvote topic without token', '401', await call('POST', '/api/votes/up/topic/$topicId', body: <String, Object?>{}), (r) => st(r, 401));
    record('votes', 'upvote topic with NO JSON body (what a naive client sends)', '200 (docs show no body)', await call('POST', '/api/votes/up/topic/$topicId', token: tokenB), (r) => st(r, 200));
    r = record('votes', 'upvote topic as B with {}', '200 + votes (docs: integer "votes")', await call('POST', '/api/votes/up/topic/$topicId', token: tokenB, body: <String, Object?>{}), (r) => st(r, 200) && r['votes'] is int);
    if (r.status == 200 && r.map.containsKey('points') && !r.map.containsKey('votes')) {
      notes.add('Vote answer is `{"points":"1"}` (a string named `points`); the docs say `{"votes": integer}`.');
    }
    record('votes', 'upvote the same topic again as B (repeat)', '200 or 4xx; record behaviour', await call('POST', '/api/votes/up/topic/$topicId', token: tokenB, body: <String, Object?>{}), (r) => r.status == 200 || is4xx(r));
    record('votes', 'topic score after repeat', 'score 1 (one vote per user)', await call('GET', '/api/topics/$topicSlug'), (r) => r['score'] == 1);
    record('votes', 'downvote the same topic as B (switch)', '200', await call('POST', '/api/votes/down/topic/$topicId', token: tokenB, body: <String, Object?>{}), (r) => st(r, 200));
    record('votes', 'topic score after switch', 'score -1', await call('GET', '/api/topics/$topicSlug'), (r) => r['score'] == -1);
    record('votes', 'downvote again as B (repeat/remove?)', '200 or 4xx; record behaviour', await call('POST', '/api/votes/down/topic/$topicId', token: tokenB, body: <String, Object?>{}), (r) => r.status == 200 || is4xx(r));
    record('votes', 'topic score after second downvote', 'score -1 or 0 (docs have no remove call)', await call('GET', '/api/topics/$topicSlug'), (r) => r['score'] == -1 || r['score'] == 0);
    record('votes', 'upvote own topic as A', '200 or 403 (docs silent)', await call('POST', '/api/votes/up/topic/$topicId', token: tokenA, body: <String, Object?>{}), (r) => r.status == 200 || r.status == 403);
    record('votes', 'upvote comment as B', '200', await call('POST', '/api/votes/up/comment/$c1', token: tokenB, body: <String, Object?>{}), (r) => st(r, 200));
    record('votes', 'comment score after upvote', 'score 1', await call('GET', '/api/comments/$c1'), (r) => r['score'] == 1);
    record('votes', 'upvote own comment as A', '200 or 403 (docs silent)', await call('POST', '/api/votes/up/comment/$c1', token: tokenA, body: <String, Object?>{}), (r) => r.status == 200 || r.status == 403);
    record('votes', 'upvote unknown topic', '404', await call('POST', '/api/votes/up/topic/99999999', token: tokenB, body: <String, Object?>{}), (r) => st(r, 404));
    record('votes', 'upvote with bad {type}', '4xx', await call('POST', '/api/votes/up/forum/$forumId', token: tokenB, body: <String, Object?>{}), is4xx);

    // ------------------------------------------------------------- reports
    record('reports', 'report topic without token', '401', await call('POST', '/api/reports/type/topic/$topicId', body: {'type': 'Offensive'}), (r) => st(r, 401));
    r = record('reports', 'documented route POST /{type}/{id}/reports', '200 per docs', await call('POST', '/api/topic/$topicId/reports', token: tokenB, body: {'type': 'Offensive', 'body': 'x'}), (r) => st(r, 200));
    r = record('reports', 'report topic via /reports/type/topic/{id} (route the app uses)', '200', await call('POST', '/api/reports/type/topic/$topicId', token: tokenB, body: {'type': 'Offensive', 'body': 'rude'}), (r) => st(r, 200) && r['id'] is int);
    track('report', r, 'B');
    final reportTopic = (r['id'] as int?) ?? 0;
    r = record('reports', 'report comment with type "Other"', '200', await call('POST', '/api/reports/type/comment/$c1', token: tokenB, body: {'type': 'Other'}), (r) => st(r, 200));
    final reportComment = (r['id'] as int?) ?? 0;
    for (final t in ['Spam', 'Harassment', 'Inappropriate']) {
      record('reports', 'report with type "$t"', '200 or 422 (docs do not list types)', await call('POST', '/api/reports/type/comment/$c1', token: tokenB, body: {'type': t}), (rr) {
        if (rr.status == 200) track('report', rr, 'B');
        return rr.status == 200 || rr.status == 422;
      });
    }
    record('reports', 'report without type', '422', await call('POST', '/api/reports/type/topic/$topicId', token: tokenB, body: {'body': 'no type'}), (r) => st(r, 422));
    record('reports', 'report unknown topic', '404', await call('POST', '/api/reports/type/topic/99999999', token: tokenB, body: {'type': 'Offensive'}), (r) => st(r, 404));
    r = record('reports', 'report the same topic twice as B', '200 or 4xx; record behaviour', await call('POST', '/api/reports/type/topic/$topicId', token: tokenB, body: {'type': 'Offensive'}), (r) => r.status == 200 || is4xx(r));
    if (r.status == 200) track('report', r, 'B');
    record('reports', 'GET /reports (documented) as normal user', '403 or 200', await call('GET', '/api/reports', token: tokenA), (r) => st(r, 200) || st(r, 403));
    record('reports', 'a reported topic still shows its own body and status', 'docs silent: record behaviour', await call('GET', '/api/topics/$topicSlug'), (r) => r.status == 200);
    if (checks.last.actual.contains('pending moderation')) {
      notes.add('Reporting a topic or comment replaces its `body` with "This content has been reported and is pending moderation." and sets `status` to "Pending Review" in every GET (author included) until the report is removed; deleting the report restores the original text.');
    }
    record('reports', 'topic lists the report in `reports`', '200 + non-empty reports', await call('GET', '/api/topics/$topicSlug'), (r) => r['reports'] is List && (r['reports'] as List).isNotEmpty);
    record('reports', 'delete the report as its author (B)', '200', await call('DELETE', '/api/reports/$reportTopic', token: tokenB), (r) => st(r, 200));
    record('reports', 'delete the comment report while the comment still exists', '200', await call('DELETE', '/api/reports/$reportComment', token: tokenB), (r) => st(r, 200));
    record('reports', 'topic body is restored after the report is deleted', 'body "Edited post", status Active', await call('GET', '/api/topics/$topicSlug'), (r) => r['body'] == 'Edited post' && r['status'] == 'Active');

    // ------------------------------------------------------------- delete own / others
    record('delete', 'delete topic as non-author B', '403', await call('DELETE', '/api/topics/$topicId', token: tokenB), (r) => st(r, 403));
    record('delete', 'delete unknown topic', '404', await call('DELETE', '/api/topics/99999999', token: tokenA), (r) => st(r, 404));
    record('delete', 'delete own comment c1 (has 11 nested replies)', '200', await call('DELETE', '/api/comments/$c1', token: tokenA), (r) => st(r, 200));
    record('delete', 'replies are gone with their parent (cascade)', '200 + comments []', await call('GET', '/api/topics/$topicSlug'), (r) => st(r, 200) && (r['comments'] as List).isEmpty);
    record('delete', 'GET deleted comment', '404', await call('GET', '/api/comments/$c1'), (r) => st(r, 404));
    if (args.contains('--orphan-report')) {
      // A report whose comment was deleted first.
      r = await call('POST', '/api/comments/type/topic/$topicId', token: tokenA, body: {'body': 'Reported then deleted', 'status': 'Active'});
      final c3 = (r['id'] as int?) ?? 0;
      r = await call('POST', '/api/reports/type/comment/$c3', token: tokenB, body: {'type': 'Other'});
      final orphanReport = (r['id'] as int?) ?? 0;
      await call('DELETE', '/api/comments/$c3', token: tokenA);
      r = record('delete', 'delete a report after its comment was deleted', '200', await call('DELETE', '/api/reports/$orphanReport', token: tokenB), (r) => st(r, 200));
      if (r.status == 500) notes.add('Report $orphanReport could not be removed (HTTP 500) because its comment was deleted first; it stays on the demo key as an orphan.');
    }
    record('delete', 'delete the same comment twice', '404', await call('DELETE', '/api/comments/$c1', token: tokenA), (r) => st(r, 404));
    record('delete', 'delete own topic', '200', await call('DELETE', '/api/topics/$topicId', token: tokenA), (r) => st(r, 200));
    record('delete', 'GET deleted topic', '404', await call('GET', '/api/topics/$topicSlug'), (r) => st(r, 404));

    // ------------------------------------------------------------- logout
    record('logout', 'logout without token', '401', await call('POST', '/api/users/logout'), (r) => st(r, 401));
    final loggedOutToken = tokenA;
    record('logout', 'logout A', '200', await call('POST', '/api/users/logout', token: loggedOutToken, body: <String, Object?>{}), (r) => st(r, 200));
    record('logout', 'GET /users/me with the logged-out token', '401', await call('GET', '/api/users/me', token: loggedOutToken), (r) => st(r, 401));
    record('logout', 'write with the logged-out token', '401', await call('POST', '/api/forums/$forumId/topics', token: loggedOutToken, body: {'title': 'x', 'status': 'Active', 'type': 'Post'}), (r) => st(r, 401));
    record('logout', 'logout again with the same token', '401', await call('POST', '/api/users/logout', token: loggedOutToken, body: <String, Object?>{}), (r) => st(r, 401));
    r = record('logout', 'login again after logout', '200 + new token', await call('POST', '/api/users/login', body: {'email': email('a'), 'password': pwA}), (r) => st(r, 200) && r['token'] is String);
    tokenA = (r['token'] as String?) ?? tokenA;

    // ------------------------------------------------------------- forgot password (no email is sent)
    record('users', 'forgot password for an unknown email', '200 or 404/422 (no code can be read here)', await call('POST', '/api/users/forgot', body: {'email': email('nobody')}), (r) => r.status == 200 || is4xx(r));
    record('users', 'reset with a wrong code', '400', await call('POST', '/api/users/reset', body: {'email': email('a'), 'code': '000000', 'password': 'Zz-${randomString(10)}'}), (r) => st(r, 400));
    record('users', 'register/confirm with a wrong code', '400 or 422', await call('POST', '/api/users/register/confirm', body: {'email': email('a'), 'code': '000000'}), (r) => st(r, 400) || st(r, 422));

    // ------------------------------------------------------------- users: delete
    record('users', 'delete user B as user A', '403', await call('DELETE', '/api/users/$idB', token: tokenA), (r) => st(r, 403));
    record('users', 'delete unknown user', '404 or 403', await call('DELETE', '/api/users/99999999', token: tokenA), (r) => st(r, 404) || st(r, 403));

    // ------------------------------------------------------------- the app's own client against the live API
    await clientRoundTrip(email('c'), 'Pw-${randomString(14)}');
  } finally {
    await runCleanup();
  }

  // Cleanup verification.
  final left = await call('GET', '/api/forums');
  checks.add(Check('cleanup', 'forums left after cleanup', 'same count as before the run ($preexistingForums)', 'HTTP ${left.status}, ${left.list.length} forum(s)', left.status == 200 && left.list.length == preexistingForums));

  await writeResults(out);
  client.close();
}

/// Uses the app's own [ForumsApi] (the exact code the UI calls) end to end.
Future<void> clientRoundTrip(String email, String password) async {
  Future<void> step(String what, Future<Object?> Function() run, {int? expectStatus}) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    requests++;
    try {
      final v = await run();
      checks.add(Check('app client', what, expectStatus == null ? 'succeeds' : 'ApiException $expectStatus', v == null ? 'ok' : redact('$v'), expectStatus == null));
      stdout.writeln('${expectStatus == null ? 'PASS' : 'FAIL'}  [app client] $what');
    } on ApiException catch (e) {
      final ok = expectStatus != null && e.statusCode == expectStatus;
      checks.add(Check('app client', what, expectStatus == null ? 'succeeds' : 'ApiException $expectStatus', 'ApiException ${e.statusCode}: ${redact(e.message)}', ok));
      stdout.writeln('${ok ? 'PASS' : 'FAIL'}  [app client] $what -> ${e.statusCode}');
    } catch (e) {
      checks.add(Check('app client', what, 'succeeds', 'skipped or failed: ${redact('$e')}', false));
      stdout.writeln('FAIL  [app client] $what -> $e');
    }
  }

  final api = ForumsApi(apiKey: key, client: client);
  var userId = 0;
  await step('ForumsApi.register', () async {
    final a = await api.register(name: 'Sample C', email: email, password: password);
    if (a.token == null) throw StateError('no token');
    userId = int.tryParse(a.id) ?? 0;
    if (userId > 0) {
      cleanup.add((kind: 'user', id: userId, owner: 'C'));
      creds['C'] = (email: email, pw: password);
    }
    return 'id ${a.id}';
  });
  await step('ForumsApi.login', () async => (await api.login(email: email, password: password)).token == null ? 'no token' : null);
  Forum? forum;
  await step('ForumsApi.createForum', () async {
    forum = await api.createForum(title: 'Client check ${randomString(5)}', body: 'made by the app client');
    cleanup.add((kind: 'forum', id: forum!.id, owner: 'C'));
    return 'forum ${forum!.id}';
  });
  await step('ForumsApi.listForums', () async => 'count ${(await api.listForums()).length}');
  Topic? topic;
  await step('ForumsApi.createTopic', () async {
    topic = await api.createTopic(forum!.id, title: 'Client topic', body: 'text');
    cleanup.add((kind: 'topic', id: topic!.id, owner: 'C'));
    return 'topic ${topic!.id}';
  });
  await step('ForumsApi.listTopics', () async => 'count ${(await api.listTopics(forum!.slug)).length}');
  Comment? comment;
  await step('ForumsApi.addComment', () async {
    comment = await api.addComment(topic!.id, 'client comment');
    return 'comment ${comment!.id}';
  });
  Comment? reply;
  await step('ForumsApi.addReply', () async {
    reply = await api.addReply(comment!.id, 'client reply');
    return 'reply ${reply!.id}';
  });
  await step('ForumsApi.getTopic parses the tree', () async {
    final t = await api.getTopic(topic!.slug);
    if (t.comments.length != 1 || t.comments.first.replies.length != 1) throw StateError('tree not parsed');
    return 'comments ${t.comments.length}, replies ${t.comments.first.replies.length}';
  });
  await step('ForumsApi.updateTopic', () async => (await api.updateTopic(topic!.id, body: 'edited text')).body);
  await step('ForumsApi.updateComment', () async => (await api.updateComment(comment!.id, body: 'edited comment')).body);
  await step('ForumsApi.vote up (topic)', () async => 'points ${(await api.vote('topic', topic!.id, up: true)).points}');
  await step('ForumsApi.vote down (comment)', () async => 'points ${(await api.vote('comment', comment!.id, up: false)).points}');
  await step('ForumsApi.report (comment)', () async {
    await api.report('comment', comment!.id, reason: 'Other');
    return null;
  });
  await step('ForumsApi.deleteComment', () async {
    await api.deleteComment(reply!.id);
    return null;
  });
  await step('ForumsApi.addComment with empty body -> 422', () async => api.addComment(topic!.id, ''), expectStatus: 422);
  await step('ForumsApi.deleteTopic', () async {
    await api.deleteTopic(topic!.id);
    return null;
  });
  await step('ForumsApi.deleteForum', () async {
    await api.deleteForum(forum!.id);
    return null;
  });
  await step('ForumsApi.logout', () async {
    await api.logout();
    return null;
  });
  await step('ForumsApi.listTopics on a deleted forum -> 404', () async => api.listTopics(forum!.slug), expectStatus: 404);
}

/// Deletes everything created, children first, ignoring 404 (already gone via
/// cascade). Each owner logs in afresh; users are deleted last, by themselves.
Future<void> runCleanup() async {
  stdout.writeln('--- cleanup (${cleanup.length} items)');
  final tokens = <String, String>{};
  for (final e in creds.entries) {
    final r = await call('POST', '/api/users/login', body: {'email': e.value.email, 'password': e.value.pw});
    final t = r['token'];
    if (t is String) {
      tokens[e.key] = t;
    } else {
      notes.add('Cleanup: could not log in test user ${e.key} (HTTP ${r.status}).');
    }
  }
  for (final kind in ['report', 'comment', 'topic', 'forum', 'user']) {
    for (final item in cleanup.reversed.where((c) => c.kind == kind)) {
      final path = switch (kind) {
        'report' => '/api/reports/${item.id}',
        'comment' => '/api/comments/${item.id}',
        'topic' => '/api/topics/${item.id}',
        'forum' => '/api/forums/${item.id}',
        _ => '/api/users/${item.id}',
      };
      final r = await call('DELETE', path, token: tokens[item.owner]);
      if (r.status != 200 && r.status != 404) {
        notes.add('Cleanup of $kind ${item.id} answered ${r.status}: ${redact(r.raw)}');
      }
    }
  }
}

Future<void> writeResults(String path) async {
  final b = StringBuffer()
    ..writeln('| # | Area | Check | Expected (per docs) | Actual | Result |')
    ..writeln('|---|------|-------|---------------------|--------|--------|');
  var i = 0;
  for (final c in checks) {
    i++;
    b.writeln('| $i | ${c.area} | ${c.what.replaceAll('|', '\\|')} | ${c.expected.replaceAll('|', '\\|')} | ${c.actual} | ${c.pass ? 'PASS' : 'FAIL'} |');
  }
  final failed = checks.where((c) => !c.pass).length;
  b
    ..writeln()
    ..writeln('Requests sent: $requests. Throttled (429) responses seen: $throttled. Checks: ${checks.length}, failed: $failed.')
    ..writeln()
    ..writeln('### Observations');
  for (final n in notes.toSet()) {
    b.writeln('- $n');
  }
  await File(path).writeAsString(b.toString());
  stdout.writeln('Wrote $path ($failed failed of ${checks.length}).');
}
