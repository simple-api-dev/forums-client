# Live check report: Forums API v2 (forums.simpleapi.dev)

Re-run of `tool/live_check/live_check.dart` against the **live** API on
2026-10-31, after the bug-fix release (vreddit-api-private PR #4) and, as it
turned out, after the register-parity PR (#5) too. The previous version of this
report (the 12 "API bugs or doc mismatches") is replaced by this one.

- Key: a throwaway public demo key, passed only through the `SIMPLEAPI_KEY`
  environment variable. It is not in any file, test or commit.
- Pace: about 1 request per second. 252 requests, 0 throttled (429).
- Result of the final run: **189 checks, 0 failed.** Everything the run
  created (users, forums, topics, comments, reports, votes) was deleted again,
  content first and the users last; the key's forum list is empty afterwards.
- To reproduce: `SIMPLEAPI_KEY=<key> dart run tool/live_check/live_check.dart`.
  The script writes a table of every check to `tool/live_check/results.md`
  (or the path you give it).

## How the runs went (be aware of this)

1. **Run 1** (before #5 reached production): register answered **200**, and an
   email without a dotted domain (`x@localhost`) answered **200** and created a
   user (that user was deleted in the cleanup). Everything else passed except
   one check I had written wrongly: deleting a report after its comment is
   gone answers 404, not 200, because the report is now deleted *with* the
   comment (see below).
2. **Run 2** was cut short when the sandbox disk filled up while the script
   was running, so its cleanup did not run. It had left 2 forums with their
   topics/comments/reports and 2 test users on the demo key. I deleted them
   afterwards by resetting the two test users' passwords through the test
   mailbox, logging in, deleting the forums (which cascades) and then the two
   users. The key was verified empty (no forums; comment search with
   `level`, `top`, `client`, `reply`, `probe` returns `[]`).
3. **Run 3** (final, 189/189) is the one summarised below. By then the
   register-parity change was live too: register answers **201** and `x@localhost`
   is **422** "The email format is invalid.". I did not deploy anything; I only
   observed it. The website docs copy (`/docs-api.json`) also already says 7
   forums.

## Earlier bugs: confirmed fixed live

| Earlier bug | Live now |
| --- | --- |
| Comment search with a space ("Top level") failed (500 / 404) | `200` with matches |
| Comment search for a later word ("level") found nothing / failed | `200`, finds the replies "Level 3"... too |
| Comment search with no match: 404 "No search results" | `200 []`; topic search no match is `200 []` too |
| Missing `phrase` on comment search: 404; topic search with neither phrase nor tags: 404 | `422` (both) |
| Deleting a report whose comment is gone: 500 and the report stuck forever | Cannot happen any more: the report is deleted together with its comment (`GET /api/reports/{id}` afterwards is `404`, `DELETE` is `404`, never 500) |
| Slugs with accents/emoji/`?%#` could be created but never opened | Slugs are `[a-z0-9_]+` ("Café au lait" -> `cafe_au_lait_...`, emoji and `?%` dropped); all five test titles read back with `200`; a percent-encoded path (`/api/forums/%63afe_...`) is url-decoded and opens the forum |
| Forum limit: docs said 3, behaviour was 7 | The 8th forum is `403` "Maximum number of forums (7) per developer account has been reached." The docs now say 7 |
| Failed login was 404 `Login Failed (<email>)` | `401` "Invalid email or password." for a wrong password, an unknown email and a short password; the email is not echoed |
| Duplicate register 400 | `409` |
| Malformed JSON body 422 | `400` |
| Votes answered `{"points":"1"}` (string) and needed a JSON body | `{"points": 1}` (integer); no body needed (`{}` still accepted) |
| No way to take a vote back | `DELETE /api/votes/{type}/{id}` -> `200 {"points": n}`, idempotent, `401` without a token, `404` for an unknown item |
| `GET /api/users/me` returned the bearer token | No `token` field |
| `GET /api/reports/{id}` returned the whole list | Returns that one report (`200`, object, with the saved `body`); `GET /api/reports` is an admin list (`403` for others) |
| Report `body` was dropped | Saved |
| Topic `body` was required although documented optional | Optional on create (empty and missing both `200`); update without `body` leaves the text alone; update with `""` clears it (`200`) |
| Topic type `URL` passed validation and failed in the database | `422`; `Article` is `200` |
| Same topic title twice in one forum | Distinct slug (`..._1`) |
| `GET /api/comments/abc` was 500 | `404` |
| Documented-only routes (`DELETE /api/forum/{id}`, `POST /api/{type}/{id}/reports`) | Not routed (`404`) and no longer documented |
| Short password at register was accepted / login of a short password was 422 | Register `422` (min 8); login with a short password is `401` like any wrong password |
| Part 1: register with a dotless email (`a@b`) created a user | `422`; register answers `201` (and `register/confirm` per the PR) |

The app's own client (`ForumsApi`) was also run end to end against the live
API (register, login, create a forum with an accented title and read it back
by slug, topics with and without text, comments, replies, tree parsing,
edit, vote, take a vote back, report, delete, logout): all passed.

## Still different from what you might expect (not bugs, worth knowing)

- A key sent only in an `apikey` **header** is accepted, although the docs
  describe only the query parameter.
- Logging in again replaces the user's earlier token (the token from register
  stops working with `401`). One token per user at a time.
- Reporting content replaces its `body` with "This content has been reported
  and is pending moderation." (status `Pending Review`) for everyone until the
  report is deleted, which restores it.
- Report types are `Noncompliant`, `Offensive`, `Other`; `Spam`, `Harassment`,
  `Inappropriate` are `422`.
- Voting on your own topic or comment is allowed (`200`).
- A bad `{type}` in `/comments/type/{type}/{id}` or `/votes/up/{type}/{id}` is
  a `404` with a message like "forum 63 does not exist. Create Comment Failed."
  (a little misleading, harmless).
- Topic/comment text over 4096 characters is `422`.
- `GET /api/forums/{numeric id}` and `GET /api/topics/{numeric id}` are `404`:
  forums and topics are read by slug.

## Not checked

- The admin flows (the key owner's own address, `register/confirm` with a real
  code, `GET /api/users`, `GET /api/reports` as admin, moderators, rules, tags)
  need the owner's mailbox or admin rights.
- Orphan rows left by the old (pre-cleanup) code are not visible to a non-admin
  user. During run 1 a comment search for `Top`/`level` returned two comments
  whose parent no longer existed (the key had no forums); by run 3, after the
  deploy, the same searches returned nothing from before the run, so those rows
  appear to be gone. I cannot prove that for reports or votes.
- Concurrency (the forum count is not locked, so two simultaneous creates could
  pass the limit) and the 100/minute per-IP rate limit were not exercised.

## New problems found

None in the API. Two things in my own tooling, both fixed here: the check for
"delete a report after its comment is gone" expected `200` (it is `404`, as the
report is removed with the comment), and the script had no way to recover
after being killed midway; if that happens, delete the leftovers as described
in "How the runs went".
