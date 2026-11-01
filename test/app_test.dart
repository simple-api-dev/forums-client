import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forums_client/app.dart';
import 'package:forums_client/app_state.dart';
import 'package:forums_client/key_store.dart';
import 'package:forums_client/screens/ui.dart' show demoFullMessage, demoNotice;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'forums_api_test.dart' show forumJson, topicJson, topicWithTree;

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// Links the app asked to open.
final opened = <String>[];

typedef Server = http.Response Function(http.Request);

/// Pumps the whole app against a fake server and records the requests.
/// [buildKey] stands in for the key passed with --dart-define at build time.
/// [loggedInAs] (a user id) starts the app logged in.
Future<({AppState state, List<http.Request> seen})> pumpApp(
  WidgetTester tester, {
  KeyStore? store,
  String buildKey = '',
  String? loggedInAs,
  required Server server,
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  opened.clear();
  final seen = <http.Request>[];
  final client = MockClient((r) async {
    seen.add(r);
    return server(r);
  });
  final state = AppState(store: store ?? MemoryKeyStore(), buildKey: buildKey, client: client);
  if (loggedInAs != null) {
    state.api.token = 'tok';
    state.loggedInAs(name: 'Me', id: loggedInAs);
  }
  await tester.pumpWidget(ForumsApp(state: state, openUrl: opened.add));
  await tester.pumpAndSettle();
  return (state: state, seen: seen);
}

/// Answers by "METHOD /path"; anything unlisted is a 404 so a wrong URL fails loudly.
Server router(Map<String, Server> routes) => (r) {
      final handler = routes['${r.method} ${r.url.path}'];
      return handler != null ? handler(r) : json({'message': 'Not a valid api route - not found.'}, 404);
    };

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

void main() {
  group('landing', () {
    testWidgets('opens straight on the forum list using the build-time key', (tester) async {
      final app = await pumpApp(tester, buildKey: 'build-key', server: router({'GET /api/forums': (_) => json([forumJson])}));

      expect(find.text('Probe forum'), findsOneWidget);
      expect(find.text('This demo has no key configured'), findsNothing);
      expect(app.seen.single.url.queryParameters['apikey'], 'build-key');
    });

    testWidgets('a key with no forums shows a friendly empty state', (tester) async {
      await pumpApp(tester, buildKey: 'k', server: router({'GET /api/forums': (_) => http.Response('[]', 200)}));

      expect(find.text('No forums yet'), findsOneWidget);
      expect(find.text('Create the first forum'), findsOneWidget);
    });

    testWidgets('without any key it explains so, links to get one, and calls nothing', (tester) async {
      final app = await pumpApp(tester, server: router({}));

      expect(find.text('This demo has no key configured'), findsOneWidget);
      expect(app.seen, isEmpty);

      await tester.tap(find.text('Get a free key'));
      expect(opened, ['https://keys.simpleapi.dev/?product=forums']);
    });

    testWidgets('a 401 about the key says so plainly and offers a retry button', (tester) async {
      await pumpApp(
        tester,
        store: MemoryKeyStore('bad'),
        server: router({'GET /api/forums': (_) => json({'message': 'Request failed.  API Key not found.'}, 401)}),
      );
      expect(find.text('The API key was not accepted. Check it under Settings.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a 429 asks the visitor to wait', (tester) async {
      await pumpApp(
        tester,
        buildKey: 'k',
        server: router({'GET /api/forums': (_) => json({'message': 'Throttle Limit Exceeded'}, 429)}),
      );
      expect(find.text('Too many requests. Wait a few seconds and try again.'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('a key saved in this browser overrides the build key', (tester) async {
      final app = await pumpApp(tester, store: MemoryKeyStore('own-key'), buildKey: 'build-key', server: router({'GET /api/forums': (_) => json([])}));
      expect(app.seen.single.url.queryParameters['apikey'], 'own-key');
    });

    testWidgets('"Use your own key" validates it, saves it and reloads with it', (tester) async {
      final store = MemoryKeyStore();
      final app = await pumpApp(tester, store: store, buildKey: 'build-key', server: router({'GET /api/forums': (_) => json([forumJson])}));

      await openSettings(tester);
      await tester.enterText(find.byType(TextField), '  pasted-key ');
      await tester.tap(find.text('Save key'));
      await tester.pumpAndSettle();

      expect(app.seen.map((r) => r.url.queryParameters['apikey']), ['build-key', 'pasted-key', 'pasted-key']);
      expect(store.read(), 'pasted-key');
      expect(find.text('Probe forum'), findsOneWidget);
    });

    testWidgets('a rejected own key is not saved and the API message is shown', (tester) async {
      final store = MemoryKeyStore();
      await pumpApp(
        tester,
        store: store,
        buildKey: 'build-key',
        server: router({
          'GET /api/forums': (r) => r.url.queryParameters['apikey'] == 'nope' ? json({'message': 'Request failed.  API Key not found.'}, 401) : json([]),
        }),
      );
      await openSettings(tester);
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.tap(find.text('Save key'));
      await tester.pumpAndSettle();

      expect(store.read(), isNull);
      expect(find.text('The API key was not accepted. Check it under Settings.'), findsOneWidget);
    });

    testWidgets('"Remove my key" forgets the saved key', (tester) async {
      final store = MemoryKeyStore('own-key');
      final app = await pumpApp(tester, store: store, buildKey: 'build-key', server: router({'GET /api/forums': (_) => json([])}));

      await openSettings(tester);
      await tester.tap(find.text('Remove my key'));
      await tester.pumpAndSettle();

      expect(store.read(), isNull);
      expect(app.seen.last.url.queryParameters['apikey'], 'build-key');
    });
  });

  group('accounts', () {
    testWidgets('registering from the empty state, then creating the first forum', (tester) async {
      var forums = <Map<String, Object?>>[];
      final app = await pumpApp(
        tester,
        buildKey: 'k',
        server: router({
          'GET /api/forums': (_) => json(forums),
          'POST /api/users/register': (_) => json({'name': 'Jane', 'enabled': true, 'token': 'tok-9', 'admin': false, 'id': 8}, 201),
          'POST /api/forums': (r) {
            forums = [forumJson];
            return json(forumJson);
          },
        }),
      );

      // Not logged in: the button sends you to the log in screen first.
      await tester.tap(find.text('Create the first forum'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Jane');
      await tester.enterText(fields.at(1), 'demo-user@example.invalid');
      await tester.enterText(fields.at(2), 'not-a-real-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();

      // Back on the list, now logged in, and the new forum dialog is open.
      expect(find.text('New forum'), findsWidgets);
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Probe forum');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      final post = app.seen.firstWhere((r) => r.method == 'POST' && r.url.path == '/api/forums');
      expect(post.headers['Authorization'], 'Bearer tok-9');
      expect(jsonDecode(post.body), {'title': 'Probe forum', 'status': 'Active'});
      expect(jsonDecode(post.body), isNot(contains('author_id')));
      expect(find.text('Probe forum'), findsOneWidget);
      expect(find.text('Hi, Jane'), findsOneWidget);
    });

    testWidgets('a 401 about the login on a write ends the session and opens the log in screen', (tester) async {
      final app = await pumpApp(
        tester,
        buildKey: 'k',
        loggedInAs: '8',
        server: router({
          'GET /api/forums': (_) => json([forumJson]),
          'POST /api/forums': (_) => json({'message': 'Invalid auth token. Log in again.'}, 401),
        }),
      );
      await tester.tap(find.text('New forum'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Another forum');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(app.state.loggedIn, isFalse);
      expect(find.widgetWithText(AppBar, 'Log in'), findsOneWidget);
      expect(find.text('Your session has ended. Please log in again.'), findsOneWidget);
    });

    testWidgets('the register form warns that demo accounts are public, and a full demo says so', (tester) async {
      await pumpApp(
        tester,
        buildKey: 'k',
        server: router({
          'GET /api/forums': (_) => json([]),
          'POST /api/users/register': (_) => json({'message': 'Maximum number of user accounts (25) per developer account has been reached.'}, 403),
        }),
      );
      await tester.tap(find.text('Log in / Register'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      expect(find.text(demoNotice), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Jane');
      await tester.enterText(fields.at(1), 'demo-user@example.invalid');
      await tester.enterText(fields.at(2), 'not-a-real-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();
      expect(find.text(demoFullMessage), findsOneWidget);
    });

    testWidgets('with your own key there is no demo warning', (tester) async {
      await pumpApp(tester, store: MemoryKeyStore('own'), server: router({'GET /api/forums': (_) => json([])}));
      await tester.tap(find.text('Log in / Register'));
      await tester.pumpAndSettle();
      expect(find.text(demoNotice), findsNothing);
    });

    testWidgets('a wrong password shows the API\'s 401 message on the form', (tester) async {
      await pumpApp(
        tester,
        buildKey: 'k',
        server: router({
          'GET /api/forums': (_) => json([]),
          'POST /api/users/login': (_) => json({'message': 'Invalid email or password.'}, 401),
        }),
      );
      await tester.tap(find.text('Log in / Register'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'demo-user@example.invalid');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
      expect(find.textContaining('API key was not accepted'), findsNothing);
    });

    testWidgets('logging out calls the API and shows Log in again', (tester) async {
      final app = await pumpApp(
        tester,
        buildKey: 'k',
        loggedInAs: '8',
        server: router({'GET /api/forums': (_) => json([]), 'POST /api/users/logout': (_) => http.Response('true', 200)}),
      );
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(app.seen.last.url.path, '/api/users/logout');
      expect(app.seen.last.headers['Authorization'], 'Bearer tok');
      expect(app.state.loggedIn, isFalse);
      expect(find.text('Log in / Register'), findsOneWidget);
      expect(find.text('Logged out.'), findsNothing);
    });

    testWidgets('a forum title with accents and symbols is sent as typed', (tester) async {
      final app = await pumpApp(
        tester,
        buildKey: 'k',
        loggedInAs: '8',
        server: router({'GET /api/forums': (_) => json([]), 'POST /api/forums': (_) => json({...forumJson, 'title': 'Café au lait?', 'slug': 'cafe_au_lait'})}),
      );
      await tester.tap(find.text('Create the first forum'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Café au lait?');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.textContaining('plain letters'), findsNothing);
      final post = app.seen.firstWhere((r) => r.method == 'POST');
      expect(jsonDecode(post.body)['title'], 'Café au lait?');
    });
  });

  group('topics', () {
    final routes = <String, Server>{
      'GET /api/forums': (_) => json([forumJson]),
      'GET /api/forums/probe_forum/topics': (_) => json([topicJson]),
    };

    testWidgets('a forum lists its topics', (tester) async {
      final app = await pumpApp(tester, buildKey: 'k', server: router(routes));
      await tester.tap(find.text('Probe forum'));
      await tester.pumpAndSettle();

      expect(find.text('Hello topic'), findsOneWidget);
      expect(app.seen.last.url.path, '/api/forums/probe_forum/topics');
    });

    testWidgets('starting a topic needs a title; the text is optional', (tester) async {
      final app = await pumpApp(
        tester,
        buildKey: 'k',
        loggedInAs: '8',
        server: router({...routes, 'POST /api/forums/10/topics': (_) => json(topicJson)}),
      );
      await tester.tap(find.text('Probe forum'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New topic'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
      expect(app.seen.where((r) => r.method == 'POST'), isEmpty);

      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Hello topic');
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();
      var post = app.seen.firstWhere((r) => r.method == 'POST');
      expect(jsonDecode(post.body), {'title': 'Hello topic', 'status': 'Active', 'type': 'Post'});
    });

    testWidgets('a topic with text sends the body', (tester) async {
      final app = await pumpApp(
        tester,
        buildKey: 'k',
        loggedInAs: '8',
        server: router({...routes, 'POST /api/forums/10/topics': (_) => json(topicJson)}),
      );
      await tester.tap(find.text('Probe forum'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New topic'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Hello topic');
      await tester.enterText(find.widgetWithText(TextField, 'Text (optional)'), 'first post');
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();
      final post = app.seen.firstWhere((r) => r.method == 'POST');
      expect(jsonDecode(post.body), {'title': 'Hello topic', 'status': 'Active', 'type': 'Post', 'body': 'first post'});
    });

    testWidgets('an empty forum invites the first topic', (tester) async {
      await pumpApp(tester, buildKey: 'k', server: router({...routes, 'GET /api/forums/probe_forum/topics': (_) => json([])}));
      await tester.tap(find.text('Probe forum'));
      await tester.pumpAndSettle();
      expect(find.text('No topics yet'), findsOneWidget);
    });

    testWidgets('only the forum author sees Delete forum', (tester) async {
      await pumpApp(tester, buildKey: 'k', loggedInAs: '99', server: router(routes));
      await tester.tap(find.text('Probe forum'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Delete forum'), findsNothing);
    });

    testWidgets('the forum author can delete the forum and returns to the list', (tester) async {
      var deleted = false;
      final app = await pumpApp(
        tester,
        buildKey: 'k',
        loggedInAs: '8',
        server: router({
          ...routes,
          'GET /api/forums': (_) => json(deleted ? [] : [forumJson]),
          'DELETE /api/forums/10': (_) {
            deleted = true;
            return json({'message': 'Forum deleted (10)'});
          },
        }),
      );
      await tester.tap(find.text('Probe forum'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete forum'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(app.seen.any((r) => r.method == 'DELETE' && r.url.path == '/api/forums/10'), isTrue);
      expect(find.text('No forums yet'), findsOneWidget);
    });
  });

  group('topic page', () {
    Map<String, Server> topicRoutes([Map<String, Server> extra = const {}]) => {
          'GET /api/forums': (_) => json([forumJson]),
          'GET /api/forums/probe_forum/topics': (_) => json([topicJson]),
          'GET /api/topics/hello_topic': (_) => json(topicWithTree),
          ...extra,
        };

    Future<({AppState state, List<http.Request> seen})> openTopic(WidgetTester tester, {String? loggedInAs, Map<String, Server> extra = const {}}) async {
      final app = await pumpApp(tester, buildKey: 'k', loggedInAs: loggedInAs, server: router(topicRoutes(extra)));
      await tester.tap(find.text('Probe forum'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hello topic'));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('shows the topic with its whole comment tree', (tester) async {
      await openTopic(tester);
      expect(find.text('Hello topic'), findsOneWidget);
      expect(find.text('first post'), findsOneWidget);
      expect(find.text('top comment'), findsOneWidget);
      expect(find.text('reply'), findsOneWidget);
      expect(find.text('reply to the reply'), findsOneWidget);
    });

    testWidgets('replies are indented under their parent', (tester) async {
      await openTopic(tester);
      final top = tester.getTopLeft(find.text('top comment')).dx;
      final reply = tester.getTopLeft(find.text('reply')).dx;
      final deeper = tester.getTopLeft(find.text('reply to the reply')).dx;
      expect(reply, greaterThan(top));
      expect(deeper, greaterThan(reply));
    });

    testWidgets('edit and delete show only on your own content', (tester) async {
      await openTopic(tester, loggedInAs: '8'); // wrote the topic, the top comment and the 3rd level
      // Own: topic + comment 320 + comment 322 -> 3 Edit buttons; comment 321 is user 9's.
      expect(find.text('Edit'), findsNWidgets(3));
      expect(find.text('Delete'), findsNWidgets(3));
      expect(find.text('Report'), findsNWidgets(4));
    });

    testWidgets('a logged-out visitor sees no Edit/Delete', (tester) async {
      await openTopic(tester);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('voting logged out opens the log in screen and sends nothing', (tester) async {
      final app = await openTopic(tester);
      await tester.tap(find.byTooltip('Upvote').first);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Log in'), findsOneWidget);
      expect(app.seen.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('upvote posts without a body and reloads the topic', (tester) async {
      final app = await openTopic(tester, loggedInAs: '77', extra: {'POST /api/votes/up/topic/48': (_) => json({'points': 1})});
      await tester.tap(find.byTooltip('Upvote').first);
      await tester.pumpAndSettle();

      final vote = app.seen.firstWhere((r) => r.method == 'POST');
      expect(vote.body, isEmpty);
      expect(vote.headers['Authorization'], 'Bearer tok');
      expect(find.textContaining('score is now 1'), findsOneWidget);
      expect(app.seen.last.url.path, '/api/topics/hello_topic'); // reloaded
    });

    testWidgets('downvoting a comment uses the comment type', (tester) async {
      final app = await openTopic(tester, loggedInAs: '77', extra: {'POST /api/votes/down/comment/320': (_) => json({'points': -1})});
      await tester.tap(find.byTooltip('Downvote').at(1)); // [0] is the topic
      await tester.pumpAndSettle();
      expect(app.seen.any((r) => r.url.path == '/api/votes/down/comment/320'), isTrue);
    });

    testWidgets('a vote is taken back with DELETE and the topic reloads', (tester) async {
      final app = await openTopic(tester, loggedInAs: '77', extra: {'DELETE /api/votes/topic/48': (_) => json({'points': 0})});
      await tester.tap(find.byTooltip('Take back my vote').first);
      await tester.pumpAndSettle();

      final del = app.seen.firstWhere((r) => r.method == 'DELETE');
      expect(del.url.path, '/api/votes/topic/48');
      expect(del.headers['Authorization'], 'Bearer tok');
      expect(find.textContaining('Vote taken back'), findsOneWidget);
      expect(app.seen.last.url.path, '/api/topics/hello_topic');
    });

    testWidgets('adds a top-level comment', (tester) async {
      final app = await openTopic(tester, loggedInAs: '77', extra: {'POST /api/comments/type/topic/48': (_) => json({'id': 400, 'body': 'hi'})});
      await tester.enterText(find.widgetWithText(TextField, 'Add a comment'), 'hi there');
      await tester.tap(find.text('Comment'));
      await tester.pumpAndSettle();

      final post = app.seen.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/comments/type/topic/48');
      expect(jsonDecode(post.body), {'body': 'hi there', 'status': 'Active'});
    });

    testWidgets('replies to a comment', (tester) async {
      final app = await openTopic(tester, loggedInAs: '77', extra: {'POST /api/comments/type/comment/320': (_) => json({'id': 401, 'body': 'r'})});
      await tester.tap(find.text('Reply').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Your reply'), 'my reply');
      await tester.tap(find.widgetWithText(FilledButton, 'Reply'));
      await tester.pumpAndSettle();

      final post = app.seen.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/comments/type/comment/320');
      expect(jsonDecode(post.body)['body'], 'my reply');
    });

    testWidgets('edits own topic text', (tester) async {
      final app = await openTopic(tester, loggedInAs: '8', extra: {'PUT /api/topics/48': (_) => json(topicJson)});
      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Text'), 'changed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final put = app.seen.firstWhere((r) => r.method == 'PUT');
      expect(jsonDecode(put.body), {'body': 'changed', 'status': 'Active'});
    });

    testWidgets('a 403 on edit is explained', (tester) async {
      await openTopic(tester, loggedInAs: '8', extra: {
        'PUT /api/comments/320': (_) => json({'message': "Only the comment's author, a moderator or an admin can change this comment."}, 403),
      });
      await tester.tap(find.text('Edit').at(1)); // comment 320
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Text'), 'changed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text("Only the comment's author, a moderator or an admin can change this comment."), findsOneWidget);
    });

    testWidgets('deletes own comment after confirming', (tester) async {
      final app = await openTopic(tester, loggedInAs: '8', extra: {'DELETE /api/comments/320': (_) => json({'message': 'Comment deleted (320)'})});
      await tester.tap(find.text('Delete').at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(app.seen.any((r) => r.method == 'DELETE' && r.url.path == '/api/comments/320'), isTrue);
    });

    testWidgets('deleting the topic returns to the forum', (tester) async {
      final app = await openTopic(tester, loggedInAs: '8', extra: {'DELETE /api/topics/48': (_) => json({'message': 'Topic deleted (48)'})});
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(app.seen.any((r) => r.method == 'DELETE' && r.url.path == '/api/topics/48'), isTrue);
      expect(find.text('Comments'), findsNothing); // topic page is gone
    });

    testWidgets('reports a topic, choosing the reason', (tester) async {
      final app = await openTopic(tester, loggedInAs: '77', extra: {'POST /api/reports/type/topic/48': (_) => json({'type': 'Offensive', 'id': 26})});
      await tester.tap(find.text('Report').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offensive'));
      await tester.pumpAndSettle();

      final post = app.seen.firstWhere((r) => r.method == 'POST');
      expect(jsonDecode(post.body), {'type': 'Offensive'});
      expect(find.text('Reported. Thank you.'), findsOneWidget);
    });

    testWidgets('reporting twice shows the 409 message', (tester) async {
      await openTopic(tester, loggedInAs: '77', extra: {
        'POST /api/reports/type/topic/48': (_) => json({'message': 'You have already reported this topic.'}, 409),
      });
      await tester.tap(find.text('Report').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();
      expect(find.textContaining('already reported'), findsOneWidget);
    });

    testWidgets('a reported topic is flagged (the API replaces its text)', (tester) async {
      await openTopic(tester, extra: {
        'GET /api/topics/hello_topic': (_) => json({
              ...topicJson,
              'body': 'This content has been reported and is pending moderation.',
              'status': 'Pending Review',
              'comments': [],
            }),
      });
      expect(find.text('Reported: pending moderation'), findsOneWidget);
    });

    testWidgets('an unknown topic shows the 404 and a retry button', (tester) async {
      await openTopic(tester, extra: {'GET /api/topics/hello_topic': (_) => json({'message': 'Topic hello_topic not found.'}, 404)});
      expect(find.text('Not found. It may already have been deleted.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
