# forums-client-flutter

A small Flutter **web** app that shows how to use the free
[SimpleApi Forums API v2](https://forums.simpleapi.dev/docs): forums, topics,
threaded comments, votes and reports. It is a teaching sample: no backend, no
state-management package, and the only dependency besides Flutter is
[`http`](https://pub.dev/packages/http).

**Live demo:** https://simple-api-dev.github.io/forums-client-flutter/

## Keys

This is a **reference implementation**: the live demo opens straight on the
forum list, with no sign-in or key prompt, because a demo key is compiled into
it at build time. A brand-new key has no forums yet, so the first thing you see
may be the friendly "No forums yet" screen: register, then create the first
forum.

**Use your own key.** In the app open **Settings -> Use your own key** and paste
a key; it is checked with one call and kept only in your browser's
localStorage, where it overrides the demo key. Get a free key at
https://keys.simpleapi.dev/?product=forums (product URL
`https://forums.simpleapi.dev`). Keys are sent only to `forums.simpleapi.dev`,
as the `apikey` query parameter. Reading needs just the key; writing (forums,
topics, comments, votes, reports) also needs a logged-in user, whom you can
register inside the app. Users belong to your key, so every developer has their
own set of users, and the API uses the logged-in user as the author: the client
never sends one.

**Set the demo key for your deployment.** The key is read with
`String.fromEnvironment('SIMPLEAPI_KEY')` and nothing is ever committed:

1. In your repository go to **Settings -> Secrets and variables -> Actions ->
   Variables** and add a repository **variable** named `SIMPLEAPI_KEY`.
2. Push to `main` (or run the workflow). It builds with
   `--dart-define=SIMPLEAPI_KEY=...`.

**Anything passed with `--dart-define` ends up in the compiled JavaScript, so
anyone can read it from the deployed site.** Use a free key made for a public
demo. If the variable is empty, the app shows "This demo has no key
configured" with a link to get one.

## Screens and the API calls they use

| Screen | What it does | Calls |
| --- | --- | --- |
| **Forums** (`forums_screen.dart`) | The landing screen. Lists the forums of the key, or an empty state. **New forum** asks you to log in first. | `GET /api/forums`, `POST /api/forums` |
| **Settings** (`settings_screen.dart`) | Use your own key instead of the demo key (or go back to it). | `GET /api/forums` (used to check the key) |
| **Log in / Register** (`auth_screen.dart`) | Get a token. Opened automatically when you try to write or vote; **Log out** is in the app bar. | `POST /api/users/register`, `POST /api/users/login`, `POST /api/users/logout` |
| **Forum** (`forum_screen.dart`) | The topics of one forum; start a topic; the forum's author can delete the forum. | `GET /api/forums/{slug}/topics`, `POST /api/forums/{id}/topics`, `DELETE /api/forums/{id}` |
| **Topic** (`topic_screen.dart`) | A topic with its whole comment tree (replies indented). Comment, reply, upvote/downvote topics and comments, edit and delete your own, report anything. | `GET /api/topics/{slug}`, `POST /api/comments/type/topic/{id}`, `POST /api/comments/type/comment/{id}`, `PUT /api/topics/{id}`, `PUT /api/comments/{id}`, `DELETE /api/topics/{id}`, `DELETE /api/comments/{id}`, `POST /api/votes/up/{type}/{id}`, `POST /api/votes/down/{type}/{id}`, `DELETE /api/votes/{type}/{id}` (take a vote back), `POST /api/reports/type/{type}/{id}` |

Every call lives in [`lib/forums_api.dart`](lib/forums_api.dart), one method
per endpoint with a comment naming it. The rest of the app never touches HTTP.
The login token is held in memory only, so reloading the page logs you out
while your own key, if you saved one, stays.

Not in this sample: moderator tools, rules, tags, search, and the admin flows
(the admin is the user whose email is the one your key belongs to; see the
[full docs](https://forums.simpleapi.dev/docs)).

## Things worth knowing about the API

The API was fixed after the first version of this sample was written (the
earlier workarounds are gone from the code). What a client should expect now;
the evidence from a run against the live service is in
[`tool/live_check/REPORT.md`](tool/live_check/REPORT.md):

- `status` is one of `Draft`, `Active`, `Locked`, `Removed`, `Pending Review`
  (the sample sends `Active`); anything else is a `422`. Topic `type` is `Post`,
  `Video`, `Article` or `Image` (`URL` is a `422`).
- Topic `body` is optional on create and update.
- A vote needs no body. The answer is `{"points": <int>}`, the content's new
  total score. `DELETE /api/votes/{type}/{id}` takes your vote back (same
  answer; harmless if you had none).
- A failed login is `401` "Invalid email or password."; a duplicate register is
  `409`; malformed JSON is `400`. Register answers `201` (older deployments
  `200`), so the sample accepts any `2xx`.
- Reports go to `POST /api/reports/type/{type}/{id}`. Report types are
  `Noncompliant`, `Offensive` and `Other`; the sample offers the last two.
- A reported topic/comment has its `body` replaced by "This content has been
  reported and is pending moderation." (status `Pending Review`) until the
  report is removed.
- Slugs are generated url-safe (`a-z`, `0-9`, `_`; accents transliterated), so
  any title works. Paths are url-decoded, and the client url-encodes the slug it
  puts in a path anyway.
- Logging in again invalidates the user's earlier token.
- Errors come back as `{"message": "..."}`; the app shows that text next to a
  plain-language explanation of the status (`401`, `403`, `404`, `409`, `422`, `429`).
- A basic key is limited to 7 forums, 300 topics and 2000 comments (all users
  of the key together); the next one is a `403`.
- The API is rate limited, so a burst of clicks may be answered with a `429`.
- Registering with the email address your key belongs to makes the admin
  account and answers `202` with a mailed code
  (`POST /api/users/register/confirm`). The sample shows the message but does
  not implement that step; use a different address.
- Not used by the sample: search (`GET /api/topics/search`,
  `/api/comments/search`: no match is `200 []`, a missing phrase is `422`),
  `GET /api/reports/{id}` (one report) and `GET /api/users/me` (no longer
  contains the token).

## Run locally

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable; CI uses 3.47.8).

```bash
flutter pub get
flutter run -d chrome --dart-define=SIMPLEAPI_KEY=<your key>
```

(or leave `--dart-define` out and paste your key under Settings).

Run the checks the workflow runs (all HTTP is mocked, nothing calls the real API):

```bash
flutter analyze
flutter test
```

## Live check against the real API

[`tool/live_check/`](tool/live_check/) holds a script that exercises every call
the app makes, plus error and edge cases, against the real service, and writes
a table of what happened. It reads the key from the environment and never
stores it:

```bash
SIMPLEAPI_KEY=<your key> dart run tool/live_check/live_check.dart
```

It paces itself at about one request per second, backs off on `429`, uses
throw-away users with random credentials and deletes what it creates. Use a
throw-away key: it creates and removes forums, topics, comments and users.

## Project layout

```
lib/forums_api.dart       the whole API client
lib/models.dart           response classes
lib/app_state.dart        saved key + logged-in user (a ChangeNotifier)
lib/key_store*.dart       localStorage wrapper (+ in-memory one for tests)
lib/config.dart           the build-time key (SIMPLEAPI_KEY)
lib/screens/              the screens
test/                     unit tests for the client, widget tests for the app
tool/live_check/          live check script and its REPORT.md
```

## Deploy (GitHub Pages)

[`.github/workflows/pages.yml`](.github/workflows/pages.yml) runs on every push
to `main`: it installs Flutter, runs `flutter analyze` and `flutter test`,
builds with `flutter build web --release --base-href /forums-client-flutter/`
and publishes through the official `upload-pages-artifact` and `deploy-pages`
actions. In your fork or copy, add the `SIMPLEAPI_KEY` variable (see Keys) and
set **Settings -> Pages -> Source** to **GitHub Actions**. If you rename the
repository, change `--base-href` to match.
