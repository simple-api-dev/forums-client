import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:forums_client/forums_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Made-up values: these tests never touch the real API or a real key.
const fakeKey = 'test-key';
const fakeEmail = 'demo-user@example.invalid';
const fakePassword = 'not-a-real-password';

/// Builds an API whose HTTP client answers with [handler] and records requests.
(ForumsApi, List<http.Request>) apiWith(
  http.Response Function(http.Request) handler, {
  String? token,
  void Function()? onSessionExpired,
}) {
  final seen = <http.Request>[];
  final client = MockClient((request) async {
    seen.add(request);
    return handler(request);
  });
  return (ForumsApi(apiKey: fakeKey, token: token, client: client, onSessionExpired: onSessionExpired), seen);
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

// Shapes copied from real answers of forums.simpleapi.dev (ids and text made up).
/// A list answer, one page holding every row.
http.Response page(List<Object?> rows) => json({'data': rows, 'total': rows.length, 'page': 1, 'per_page': 100});

/// What register, register/confirm and login answer.
http.Response session(String token, {String name = 'Jane', int id = 8, int status = 200}) => json({
      'token': token,
      'expires_at': '2026-12-01T03:47:06Z',
      'user': {'id': id, 'name': name, 'email': fakeEmail, 'admin': false, 'enabled': true, 'created_at': '2026-11-01T03:47:06Z', 'updated_at': '2026-11-01T03:47:06Z'},
    }, status);

const forumJson = {
  'id': 10,
  'title': 'Probe forum',
  'slug': 'probe_forum',
  'body': 'desc',
  'status': 'Active',
  'user_id': 8,
  'updated_at': '2026-10-31T20:41:48Z',
  'rules_text': [],
  'reports': [],
};

const topicJson = {
  'id': 48,
  'forum_id': 10,
  'title': 'Hello topic',
  'slug': 'hello_topic',
  'body': 'first post',
  'url': null,
  'type': 'Post',
  'status': 'Active',
  'user_id': 8,
  'updated_at': '2026-10-31T20:41:56Z',
  'tag_names': [],
  'reports': [],
  'score': 0,
};

/// A topic with one comment, one reply and a reply to the reply.
final topicWithTree = {
  ...topicJson,
  'comments': [
    {
      'id': 320,
      'commentable_id': 48,
      'commentable_type': r'App\Models\Topic',
      'body': 'top comment',
      'status': 'Active',
      'user_id': 8,
      'locked_at': null,
      'updated_at': '2026-10-31T20:42:11Z',
      'reports': [],
      'score': 0,
      'comments': [
        {
          'id': 321,
          'commentable_id': 320,
          'commentable_type': r'App\Models\Comment',
          'body': 'reply',
          'status': 'Active',
          'user_id': 9,
          'score': 2,
          'comments': [
            {'id': 322, 'commentable_id': 321, 'body': 'reply to the reply', 'status': 'Active', 'user_id': 8, 'score': 0, 'comments': []},
          ],
        },
      ],
    },
  ],
};

void main() {
  test('sends the key as the apikey query parameter, not as a header', () async {
    final (api, seen) = apiWith((_) => page([]));
    await api.listForums();

    final r = seen.single;
    expect(r.method, 'GET');
    expect(r.url.host, 'forums.simpleapi.dev');
    expect(r.url.path, '/api/forums');
    expect(r.url.queryParameters['apikey'], fakeKey);
    expect(r.headers.containsKey('Authorization'), isFalse);
    expect(r.headers.values.any((v) => v.contains(fakeKey)), isFalse);
  });

  test('a new key has no forums: empty data is an empty list', () async {
    final (api, _) = apiWith((_) => page([]));
    expect(await api.listForums(), isEmpty);
  });

  test('parses forums (user_id is an integer)', () async {
    final (api, _) = apiWith((_) => page([forumJson]));
    final f = (await api.listForums()).single;
    expect(f.id, 10);
    expect(f.slug, 'probe_forum');
    expect(f.userId, 8);
  });

  test('lists topics of a forum by slug', () async {
    final (api, seen) = apiWith((_) => page([topicJson]));
    final topics = await api.listTopics('probe_forum');
    expect(seen.single.url.path, '/api/forums/probe_forum/topics');
    expect(topics.single.title, 'Hello topic');
    expect(topics.single.forumId, 10);
  });

  test('a list is read page by page until total is reached', () async {
    final (api, seen) = apiWith((r) {
      final number = int.parse(r.url.queryParameters['page']!);
      return json({'data': [{...topicJson, 'id': number}], 'total': 2, 'page': number, 'per_page': 100});
    });
    final topics = await api.listTopics('probe_forum');
    expect(topics.map((t) => t.id), [1, 2]);
    expect(seen.map((r) => r.url.queryParameters['page']), ['1', '2']);
    expect(seen.first.url.queryParameters['per_page'], '100');
  });

  test('reads never send the token, so a token that ran out cannot break a public list', () async {
    final (api, seen) = apiWith((r) => r.url.path.endsWith('hello_topic') ? json(topicJson) : page([]), token: 'old');
    await api.listForums();
    await api.listTopics('probe_forum');
    await api.getTopic('hello_topic');
    expect(seen.length, 3);
    for (final r in seen) {
      expect(r.headers.containsKey('Authorization'), isFalse);
    }
    expect(api.token, 'old');
  });

  test('reads a topic by slug and parses the nested comment tree', () async {
    final (api, seen) = apiWith((_) => json(topicWithTree));
    final t = await api.getTopic('hello_topic');
    expect(seen.single.url.path, '/api/topics/hello_topic');
    final c = t.comments.single;
    expect(c.body, 'top comment');
    expect(c.replies.single.body, 'reply');
    expect(c.replies.single.score, 2);
    expect(c.replies.single.replies.single.body, 'reply to the reply');
  });

  test('slugs are url-encoded into the path (the API url-decodes it), never twice', () async {
    // Url-safe slugs are untouched.
    var (api, seen) = apiWith((_) => json(topicJson));
    await api.getTopic('hello_topic_1');
    expect(seen.single.url.path, '/api/topics/hello_topic_1');
    // Older slugs with accents, emoji or reserved characters are encoded once.
    (api, seen) = apiWith((_) => json(topicJson));
    await api.getTopic('café_au_lait?100%_#1/2 \u{1F600}');
    expect(seen.single.url.toString(), isNot(contains('%25C3')));
    expect(seen.single.url.path, '/api/topics/caf%C3%A9_au_lait%3F100%25_%231%2F2%20%F0%9F%98%80');
    expect(seen.single.url.pathSegments.last, 'café_au_lait?100%_#1/2 \u{1F600}');
    (api, seen) = apiWith((_) => page([topicJson]));
    await api.listTopics('café');
    expect(seen.single.url.path, '/api/forums/caf%C3%A9/topics');
  });

  group('users', () {
    test('register returns a token and the user id, and the api uses it', () async {
      final (api, seen) = apiWith((_) => session('tok-1', status: 201));
      final a = await api.register(name: 'Jane', email: fakeEmail, password: fakePassword);
      expect(a.token, 'tok-1');
      expect(a.id, 8);
      expect(a.name, 'Jane');
      expect(api.token, 'tok-1');
      expect(seen.single.url.path, '/api/users/register');
      expect(jsonDecode(seen.single.body), {'name': 'Jane', 'email': fakeEmail, 'password': fakePassword});
    });

    test('register answers 201 with a token', () async {
      final (api, _) = apiWith((_) => session('tok-201', status: 201));
      final a = await api.register(name: 'Jane', email: fakeEmail, password: fakePassword);
      expect(a.token, 'tok-201');
    });

    test('register answering 202 (the key owner\'s email) gives no token', () async {
      final (api, _) = apiWith((_) => json({'message': 'A code was emailed.', 'confirmation_required': true}, 202));
      final a = await api.register(name: 'Owner', email: fakeEmail, password: fakePassword);
      expect(a.token, isNull);
      expect(a.message, 'A code was emailed.');
      expect(api.token, isNull);
    });

    test('login failure is a 401 with the API message', () async {
      final (api, _) = apiWith((_) => json({'message': 'Invalid email or password.'}, 401));
      await expectLater(
        api.login(email: fakeEmail, password: 'wrong'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401).having((e) => e.message, 'message', 'Invalid email or password.')),
      );
    });

    test('register errors: duplicate email is 409, bad email and short password are 422', () async {
      var (api, _) = apiWith((_) => json({'message': 'User registration failed, email already registered to this developer account.'}, 409));
      await expectLater(api.register(name: 'a', email: fakeEmail, password: fakePassword), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)));
      (api, _) = apiWith((_) => json({'message': 'The email must be a valid email address.'}, 422));
      await expectLater(api.register(name: 'a', email: 'nope', password: fakePassword), throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('valid email'))));
      (api, _) = apiWith((_) => json({'message': 'The password must be at least 8 characters.'}, 422));
      await expectLater(api.register(name: 'a', email: fakeEmail, password: 'abc'), throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('8 characters'))));
    });

    test('logout sends the token, then forgets it; an already-invalid token still throws 401', () async {
      final (api, seen) = apiWith((_) => json({'message': 'Logged out.'}), token: 'tok-1');
      await api.logout();
      expect(seen.single.headers['Authorization'], 'Bearer tok-1');
      expect(seen.single.url.path, '/api/users/logout');
      expect(api.token, isNull);

      final (api2, _) = apiWith((_) => json({'message': 'Invalid auth token. Log in again.'}, 401), token: 'old');
      await expectLater(api2.logout(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
    });
  });

  group('writing', () {
    test('createForum sends title and status Active, a bearer token and no author', () async {
      final (api, seen) = apiWith((_) => json(forumJson), token: 'tok-1');
      final f = await api.createForum(title: 'Probe forum', body: 'desc');
      final r = seen.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/api/forums');
      expect(r.headers['Authorization'], 'Bearer tok-1');
      expect(r.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(r.body), {'title': 'Probe forum', 'status': 'Active', 'body': 'desc'});
      expect(f.slug, 'probe_forum');
    });

    test('createForum omits an empty description', () async {
      final (api, seen) = apiWith((_) => json(forumJson), token: 't');
      await api.createForum(title: 'x');
      expect(jsonDecode(seen.single.body), {'title': 'x', 'status': 'Active'});
    });

    test('createTopic sends body, type Post and status Active', () async {
      final (api, seen) = apiWith((_) => json(topicJson), token: 't');
      await api.createTopic(10, title: 'Hello topic', body: 'first post');
      expect(seen.single.url.path, '/api/forums/10/topics');
      expect(jsonDecode(seen.single.body), {'title': 'Hello topic', 'status': 'Active', 'type': 'Post', 'body': 'first post'});
    });

    test('a topic needs no text: the body is left out', () async {
      final (api, seen) = apiWith((_) => json({...topicJson, 'body': ''}), token: 't');
      final t = await api.createTopic(10, title: 'Video topic');
      expect(jsonDecode(seen.single.body), {'title': 'Video topic', 'status': 'Active', 'type': 'Post'});
      expect(t.body, '');
    });

    test('comment on a topic and reply to a comment use the type in the path', () async {
      final (api, seen) = apiWith((_) => json({'id': 5, 'body': 'x', 'status': 'Active', 'user_id': 8, 'comments': []}), token: 't');
      await api.addComment(48, 'top comment');
      await api.addReply(320, 'reply');
      expect(seen[0].url.path, '/api/comments/type/topic/48');
      expect(seen[1].url.path, '/api/comments/type/comment/320');
      expect(jsonDecode(seen[1].body), {'body': 'reply', 'status': 'Active'});
    });

    test('edit and delete', () async {
      final (api, seen) = apiWith((r) => r.method == 'DELETE' ? json({'message': 'deleted'}) : json({...topicJson, 'body': 'new'}), token: 't');
      expect((await api.updateTopic(48, body: 'new')).body, 'new');
      await api.updateComment(320, body: 'new');
      await api.deleteTopic(48);
      await api.deleteComment(320);
      await api.deleteForum(10);
      expect(seen.map((r) => '${r.method} ${r.url.path}'), [
        'PUT /api/topics/48',
        'PUT /api/comments/320',
        'DELETE /api/topics/48',
        'DELETE /api/comments/320',
        'DELETE /api/forums/10',
      ]);
      // a PUT changes only what is sent: an edit must not reset the status
      expect(jsonDecode(seen.first.body), {'body': 'new'});
      expect(jsonDecode(seen[1].body), {'body': 'new'});
    });

    test('voting sends no body and answers the new integer score', () async {
      final (api, seen) = apiWith((_) => json({'points': 1}), token: 't');
      final v = await api.vote('topic', 48, up: true);
      expect(v.points, 1);
      expect(seen.single.method, 'POST');
      expect(seen.single.url.path, '/api/votes/up/topic/48');
      expect(seen.single.body, isEmpty);
      expect((await api.vote('comment', 1, up: false)).points, 1);
      expect(seen.last.url.path, '/api/votes/down/comment/1');
    });

    test('a vote is taken back with DELETE /api/votes/{type}/{id}', () async {
      final (api, seen) = apiWith((_) => json({'message': 'Vote removed.'}), token: 't');
      await api.removeVote('comment', 320);
      expect('${seen.single.method} ${seen.single.url.path}', 'DELETE /api/votes/comment/320');
      expect(seen.single.headers['Authorization'], 'Bearer t');
      expect(seen.single.body, isEmpty);
    });

    test('report uses /reports/type/{type}/{id}', () async {
      final (api, seen) = apiWith((_) => json({'type': 'Offensive', 'user_id': 9, 'status': 'Pending Review', 'id': 26}), token: 't');
      await api.report('topic', 48, reason: 'Offensive');
      expect(seen.single.url.path, '/api/reports/type/topic/48');
      expect(jsonDecode(seen.single.body), {'type': 'Offensive'});
    });

    test('reporting twice is a 409', () async {
      final (api, _) = apiWith((_) => json({'message': 'You have already reported this topic.'}, 409), token: 't');
      await expectLater(api.report('topic', 48, reason: 'Other'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)));
    });
  });

  group('errors', () {
    test('403 when editing someone else\'s content carries the API message', () async {
      final (api, _) = apiWith((_) => json({'message': "Only the topic's author, a moderator or an admin can change this topic."}, 403), token: 't');
      await expectLater(api.updateTopic(48, body: 'x'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403).having((e) => e.message, 'message', contains('author'))));
    });

    test('401 without a key, 404 for an unknown topic', () async {
      var (api, _) = apiWith((_) => json({'message': 'Unauthorized.  Please provide a valid apikey.'}, 401));
      await expectLater(api.listForums(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
      (api, _) = apiWith((_) => json({'message': 'Topic nope not found.'}, 404));
      await expectLater(api.getTopic('nope'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)));
    });

    test('a 500 with the framework\'s pretty-printed JSON still gives a message', () async {
      final (api, _) = apiWith((_) => http.Response('{\n    "message": "Server Error"\n}', 500));
      await expectLater(api.listForums(), throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Server Error')));
    });

    test('a non-JSON error body gives a generic message with the status', () async {
      final (api, _) = apiWith((_) => http.Response('<html>Bad gateway</html>', 502));
      await expectLater(api.listForums(), throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Request failed (HTTP 502).')));
    });

    test('a network failure becomes an ApiException with status 0', () async {
      final api = ForumsApi(apiKey: fakeKey, client: MockClient((_) async => throw http.ClientException('offline')));
      await expectLater(
        api.listForums(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'status', 0)
            .having((e) => e.message, 'message', 'Could not reach forums.simpleapi.dev. Check your connection and try again.')),
      );
    });

    test('login and register never send the Bearer token, even when one is set', () async {
      final (api, seen) = apiWith((_) => session('new', status: 201), token: 'old');
      await api.login(email: fakeEmail, password: fakePassword);
      await api.register(name: 'Jane', email: fakeEmail, password: fakePassword);
      expect(seen.map((r) => r.url.path), ['/api/users/login', '/api/users/register']);
      for (final r in seen) {
        expect(r.headers.containsKey('Authorization'), isFalse);
      }
      expect(api.token, 'new');
    });

    test('a 401 about the token on a logged-in call drops the token and tells the app', () async {
      var expired = 0;
      final (api, _) = apiWith((_) => json({'message': 'Invalid auth token. Log in again.'}, 401), token: 'old', onSessionExpired: () => expired++);
      await expectLater(api.createForum(title: 'x'), throwsA(isA<ApiException>().having((e) => e.sessionEnded, 'sessionEnded', isTrue)));
      expect(api.token, isNull);
      expect(expired, 1);
    });

    test('a 401 about the key keeps the login', () async {
      var expired = 0;
      final (api, _) = apiWith(
        (_) => json({'message': 'Unauthorized. Please provide a valid apikey. Get a free key at https://keys.simpleapi.dev/?product=forums'}, 401),
        token: 'tok',
        onSessionExpired: () => expired++,
      );
      await expectLater(
        api.createForum(title: 'x'),
        throwsA(isA<ApiException>().having((e) => e.keyRejected, 'keyRejected', isTrue).having((e) => e.sessionEnded, 'sessionEnded', isFalse)),
      );
      expect(api.token, 'tok');
      expect(expired, 0);
    });

    test('a wrong password on login is a plain 401 and does not end a session', () async {
      var expired = 0;
      final (api, _) = apiWith((_) => json({'message': 'Invalid email or password.'}, 401), token: 'tok', onSessionExpired: () => expired++);
      await expectLater(api.login(email: fakeEmail, password: 'wrong'), throwsA(isA<ApiException>().having((e) => e.sessionEnded, 'sessionEnded', isFalse)));
      expect(api.token, 'tok');
      expect(expired, 0);
    });

    test('429 is reported as such', () async {
      final (api, _) = apiWith((_) => json({'message': 'Throttle Limit Exceeded'}, 429));
      await expectLater(api.listForums(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 429)));
    });
  });
}
