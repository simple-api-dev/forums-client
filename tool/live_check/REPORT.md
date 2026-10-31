# Live check report: Forums API v2

**What this is.** A record of what was tried against the real service
(`https://forums.simpleapi.dev`) with the throwaway demo key, using
[`live_check.dart`](live_check.dart) in this folder. It shows what was tried and
what came back. It does **not** show that the API is bug free: only the calls
and cases listed below were exercised, once each, by one client, in a few runs
on 2026-10-31.

**How it ran.** The key came from the `SIMPLEAPI_KEY` environment variable and
is not written anywhere. Two test users (plus one more for the app-client part)
with random emails and passwords were registered per run. Requests were paced
at about one per second; the script backs off on `429`. **No `429` was ever
returned** (about 217 requests in the final run), so the back-off path was
never exercised live. Recorded response bodies are shortened and tokens,
emails and the key are redacted.

**Reading the table.** "Expected" is what the Swagger docs
(`/docs-api.json`) say or imply. Where the docs are silent the column says so
and the check passes on any sensible answer, with the behaviour recorded.
**FAIL means the API did not do what the docs say**; it does not always mean a
defect in the API. Each FAIL is explained under "API bugs or doc mismatches".

## Summary

- Requests sent:217. Throttled (429) responses seen: 0. Checks: 167, failed: 10.
- 157 of 167 checks pass. The 10 FAILs are API-versus-docs differences (listed
  below); none is a failure of the app.
- The app's own client (`ForumsApi`) was run end to end against the live API
  (the "app client" rows): register, login, create forum/topic/comment/reply,
  edit, vote, report, delete, logout.
- Nothing in any response mentioned `Carbon`, a date parse error, or a `body`
  error beyond the validation messages in the table. See "A note on `body` and
  Carbon" below.
- **Left behind on the key (cleanup the API did not allow):** two forums
  (`limit probe`, `limit probe 2`, ids 38 and 39) and a few orphan report rows.
  See "Cleanup leftovers". The key owner can remove them with the admin account.

## Every check

| # | Area | Check | Expected (per docs) | Actual | Result |
|---|------|-------|---------------------|--------|--------|
| 1 | apikey | GET /forums without apikey | 401 | HTTP 401 {"message":"Unauthorized.  Please provide a valid apikey.  Visit forums.simpleapi.dev\/get-key for your free a... | PASS |
| 2 | apikey | GET /forums with unknown apikey | 401 | HTTP 401 {"message":"Request failed.  API Key not found."} | PASS |
| 3 | apikey | GET /forums with malformed apikey | 401 | HTTP 401 {"message":"Request failed.  API Key not found."} | PASS |
| 4 | apikey | apikey sent as a header only (docs say query) | docs only describe the query form; 200 or 401 | HTTP 200 [{"id":38,"title":"limit probe","slug":"limit_probe","body":"","status":"Active","author_id":"23","updated_at"... | PASS |
| 5 | apikey | POST /users/login with bad apikey | 401 | HTTP 401 {"message":"Request failed.  API Key not found."} | PASS |
| 6 | forums | GET /forums on a fresh key | 200 + list (empty on a fresh key) | HTTP 200 [{"id":38,"title":"limit probe","slug":"limit_probe","body":"","status":"Active","author_id":"23","updated_at"... | PASS |
| 7 | users | register user A | 200 + token/id | HTTP 200 {"name":"Sample A","email":"<email>","enabled":true,"token":"<redacted>","admin":false,"id":30} | PASS |
| 8 | users | register user B | 200 + token/id | HTTP 200 {"name":"Sample B","email":"<email>","enabled":true,"token":"<redacted>","admin":false,"id":31} | PASS |
| 9 | users | register duplicate email | 4xx (docs silent; 409/422 expected) | HTTP 400 {"message":"User registration failed, email already registered to this developer account."} | PASS |
| 10 | users | register bad email | 422 | HTTP 422 {"message":"The email must be a valid email address."} | PASS |
| 11 | users | register short password (3 chars) | 4xx (docs silent about a minimum) | HTTP 422 {"message":"The password must be at least 8 characters."} | PASS |
| 12 | users | register without name | 422 | HTTP 422 {"message":"The name field is required."} | PASS |
| 13 | users | register with empty body | 422 | HTTP 422 {"message":"The name field is required.  The email field is required.  The password field is required."} | PASS |
| 14 | users | register with non-JSON body | 4xx | HTTP 422 {"message":"The email must be a valid email address.  The password field is required."} | PASS |
| 15 | users | login right credentials | 200 + token | HTTP 200 {"id":30,"name":"Sample A","email":"<email>","enabled":true,"admin":false,"token":"<redacted>","external_id":n... | PASS |
| 16 | users | login wrong password | 404 (per docs) | HTTP 404 {"message":"Login Failed (<email>)"} | PASS |
| 17 | users | login unknown email | 404 (per docs) | HTTP 404 {"message":"Login Failed (<email>)"} | PASS |
| 18 | users | login without password | 422 | HTTP 422 {"message":"The password field is required."} | PASS |
| 19 | users | GET /users/me with token | 200 + user | HTTP 200 {"id":30,"name":"Sample A","email":"<email>","enabled":true,"admin":false,"token":"<redacted>","external_id":n... | PASS |
| 20 | users | GET /users/me without token | 401 | HTTP 401 {"message":"Unauthorized. Log in and send the header \"Authorization: Bearer <token>\"."} | PASS |
| 21 | users | GET /users/me with garbage token | 401 | HTTP 401 {"message":"Invalid auth token. Log in again."} | PASS |
| 22 | users | GET /users (admin only) as normal user | 403 | HTTP 403 {"message":"List all users failed.  Only admins can list all users."} | PASS |
| 23 | users | token from register after a second login (single active token?) | docs silent: 200 (tokens independent) or 401 (replaced) | HTTP 401 {"message":"Invalid auth token. Log in again."} | PASS |
| 24 | forums | create forum without token | 401 | HTTP 401 {"message":"Unauthorized. Log in and send the header \"Authorization: Bearer <token>\"."} | PASS |
| 25 | forums | create forum with status "published" | 422 (docs do not list valid statuses) | HTTP 422 {"message":"The selected status is invalid."} | PASS |
| 26 | forums | create forum without title | 422 | HTTP 422 {"message":"The title field is required."} | PASS |
| 27 | forums | create forum with empty title | 422 | HTTP 422 {"message":"The title field is required."} | PASS |
| 28 | forums | create forum 1 as A (body omitted) | 200 + id/slug | HTTP 200 {"title":"Live check yisrzcsj","slug":"live_check_yisrzcsj","status":"Active","body":"","author_id":"30","upda... | PASS |
| 29 | forums | create forum 2 with description and an emoji title | 200 | HTTP 200 {"title":"Second yisrzcsj \ud83d\ude00","slug":"second_yisrzcsj_\ud83d\ude00","status":"Active","body":"Descri... | PASS |
| 30 | forums | create forum 3 | 200 | HTTP 200 {"title":"Third yisrzcsj","slug":"third_yisrzcsj","status":"Active","body":"","author_id":"30","updated_at":"2... | PASS |
| 31 | forums | list forums | 200 + list incl. the new ones | HTTP 200 [{"id":38,"title":"limit probe","slug":"limit_probe","body":"","status":"Active","author_id":"23","updated_at"... | PASS |
| 32 | forums | get forum by slug | 200 | HTTP 200 {"id":51,"title":"Live check yisrzcsj","slug":"live_check_yisrzcsj","body":"","status":"Active","author_id":"3... | PASS |
| 33 | forums | get forum by numeric id | 200 or 404 (docs name the param slug) | HTTP 404 {"message":"Topic 51 not found."} | PASS |
| 34 | forums | get unknown forum | 404 | HTTP 404 {"message":"Topic no_such_forum_yisrzcsj not found."} | PASS |
| 35 | forums | list topics of an empty forum | 200 + [] | HTTP 200 [] | PASS |
| 36 | forums | list topics of unknown forum | 404 | HTTP 404 {"message":"Forum no_such_forum_yisrzcsj does not exist."} | PASS |
| 37 | forums | delete forum 3 as non-author B | 403 | HTTP 403 {"message":"Only the forum's author, a moderator or an admin can delete this forum."} | PASS |
| 38 | forums | documented route DELETE /forum/{id} (singular) | 200 per docs | HTTP 404 {"message":"Not a valid api route - not found."} | FAIL |
| 39 | forums | DELETE /forums/{id} (plural, used by the app) as author | 200 | HTTP 200 {"message":"Forum deleted (53)"} | PASS |
| 40 | forums | update forum 2 as non-author B | 403 | HTTP 403 {"message":"Only the forum's author, a moderator or an admin can change this forum."} | PASS |
| 41 | forums | update forum 2 as author | 200 | HTTP 200 {"id":52,"title":"Second yisrzcsj \ud83d\ude00","slug":"second_yisrzcsj_\ud83d\ude00","body":"Edited descripti... | PASS |
| 42 | slugs | forum titled "Bob's (best) forum! yisrzcsj" can be read back by its slug | 200 (slug is URL-safe) | create HTTP 200, slug "bob's_(best)_forum!_yisrzcsj", GET HTTP 200; app guard says safe | PASS |
| 43 | slugs | forum titled "Café au lait yisrzcsj" can be read back by its slug | 200 per docs; the app refuses this title | create HTTP 200, slug "café_au_lait_yisrzcsj", GET HTTP 404; app guard says unsafe | PASS |
| 44 | slugs | forum titled "Smile 😀 yisrzcsj" can be read back by its slug | 200 per docs; the app refuses this title | create HTTP 200, slug "smile_😀_yisrzcsj", GET HTTP 404; app guard says unsafe | PASS |
| 45 | slugs | forum titled "Why? yisrzcsj" can be read back by its slug | 200 per docs; the app refuses this title | create HTTP 200, slug "why?_yisrzcsj", GET HTTP 404; app guard says unsafe | PASS |
| 46 | slugs | forum titled "100% yisrzcsj" can be read back by its slug | 200 per docs; the app refuses this title | create HTTP 200, slug "100%_yisrzcsj", GET HTTP 404; app guard says unsafe | PASS |
| 47 | forums | forum limit ("3 per basic developer account") | a forum beyond the 3rd is rejected | rejected with HTTP 403 {"message":"Maximum number of forums (3) per developer account has been reached. (Basic Acct)"} when the key already had 7 forums | FAIL |
| 48 | topics | create topic without token | 401 | HTTP 401 {"message":"Unauthorized. Log in and send the header \"Authorization: Bearer <token>\"."} | PASS |
| 49 | topics | create topic as A | 200 + id/slug | HTTP 200 {"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","status":"Active","type":"Post","body"... | PASS |
| 50 | topics | create a second topic with the same title in the same forum | docs silent: 200 (distinct slug) or 4xx | HTTP 200 {"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj_1","status":"Active","type":"Post","bod... | PASS |
| 51 | topics | create topic without title | 422 | HTTP 422 {"message":"The title field is required.  The body field is required."} | PASS |
| 52 | topics | create topic with bad type "Poem" | 422 | HTTP 422 {"message":"The body field is required.  The selected type is invalid."} | PASS |
| 53 | topics | create topic with bad status | 422 | HTTP 422 {"message":"The body field is required.  The selected status is invalid."} | PASS |
| 54 | topics | create topic with empty body (docs: body is optional) | 200 per docs | HTTP 422 {"message":"The body field is required."} | FAIL |
| 55 | topics | create topic with no body key (docs: body is optional) | 200 per docs | HTTP 422 {"message":"The body field is required."} | FAIL |
| 56 | topics | create topic in unknown forum | 404 | HTTP 404 {"message":"Forum 99999999 does not exist.  Create Topic Failed."} | PASS |
| 57 | topics | create topic with a 5000 char body | 200 or 422 | HTTP 422 {"message":"The body must not be greater than 4096 characters."} | PASS |
| 58 | topics | list topics in forum | 200 + the topic created above | HTTP 200 [{"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"First post","url":nul... | PASS |
| 59 | topics | get topic by slug (with comments key) | 200 + comments list | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"First post","url":null... | PASS |
| 60 | topics | get topic by numeric id | 200 or 404 (docs name the param id in one place, slug in the path) | HTTP 404 {"message":"Topic 58 not found."} | PASS |
| 61 | topics | get unknown topic | 404 | HTTP 404 {"message":"Topic no_such_topic_yisrzcsj not found."} | PASS |
| 62 | topics | search topics | 200 | HTTP 200 [{"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"First post","url":nul... | PASS |
| 63 | topics | search topics without phrase | 4xx (phrase is required in docs) | HTTP 404 {"message":"Search must include at least an array of [tags] or a string search [phrase]"} | PASS |
| 64 | topics | edit own topic | 200 + new body | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"Edited post","url":nul... | PASS |
| 65 | topics | edit topic as non-author B | 403 | HTTP 403 {"message":"Only the topic's author, a moderator or an admin can change this topic."} | PASS |
| 66 | topics | edit topic without token | 401 | HTTP 401 {"message":"Unauthorized. Log in and send the header \"Authorization: Bearer <token>\"."} | PASS |
| 67 | topics | edit topic with empty body (body is required in docs) | 422 | HTTP 422 {"message":"The body field is required."} | PASS |
| 68 | topics | edit topic without status | 422 | HTTP 422 {"message":"The status field is required."} | PASS |
| 69 | topics | edit unknown topic | 404 | HTTP 404 {"message":"Topic not found (99999999)"} | PASS |
| 70 | topics | get topic after edit shows new body | 200 | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"Edited post","url":nul... | PASS |
| 71 | comments | create comment without token | 401 | HTTP 401 {"message":"Unauthorized. Log in and send the header \"Authorization: Bearer <token>\"."} | PASS |
| 72 | comments | create comment on topic as A | 200 + id | HTTP 200 {"commentable_id":58,"commentable_type":"App\\Models\\Topic","status":"Active","body":"Top level","author_id":... | PASS |
| 73 | comments | create comment with empty body | 422 | HTTP 422 {"message":"The body field is required."} | PASS |
| 74 | comments | create comment without body key | 422 | HTTP 422 {"message":"The body field is required."} | PASS |
| 75 | comments | create comment with whitespace-only body | 422 | HTTP 422 {"message":"The body field is required."} | PASS |
| 76 | comments | create comment without status | 422 (status is required in docs) | HTTP 422 {"message":"The status field is required."} | PASS |
| 77 | comments | create comment on unknown topic | 404 | HTTP 404 {"message":"topic 99999999 does not exist.  Create Comment Failed."} | PASS |
| 78 | comments | create comment with bad {type} | 4xx | HTTP 404 {"message":"forum 51 does not exist.  Create Comment Failed."} | PASS |
| 79 | comments | reply to a comment as B | 200 + commentable_id = parent | HTTP 200 {"commentable_id":366,"commentable_type":"App\\Models\\Comment","status":"Active","body":"A reply from B","aut... | PASS |
| 80 | comments | reply to unknown comment | 404 | HTTP 404 {"message":"comment 99999999 does not exist.  Create Comment Failed."} | PASS |
| 81 | comments | deep reply nesting up to level 12 | 200 at each level | reached level 12 | PASS |
| 82 | comments | GET topic returns the nested tree 12 levels deep | 200, nesting preserved | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"Edited post","url":nul... | PASS |
| 83 | comments | GET /topics/{id}/comments | 200 + list | HTTP 200 [{"id":366,"commentable_id":58,"commentable_type":"App\\Models\\Topic","body":"Top level","status":"Active","a... | PASS |
| 84 | comments | GET /comments/{id} | 200 | HTTP 200 {"id":366,"commentable_id":58,"commentable_type":"App\\Models\\Topic","body":"Top level","status":"Active","au... | PASS |
| 85 | comments | GET unknown comment | 404 | HTTP 404 {"message":"Comment 99999999 not found."} | PASS |
| 86 | comments | search comments, one-word phrase | 200 + matches | HTTP 200 [{"id":339,"commentable_id":53,"commentable_type":"App\\Models\\Topic","body":"Top level","status":"Active","a... | PASS |
| 87 | comments | search comments, phrase with a space ("Top level") | 200 + matches | HTTP 500 {     "message": "Server Error" } | FAIL |
| 88 | comments | search comments, second word only ("level") | 200 + matches | HTTP 500 {     "message": "Server Error" } | FAIL |
| 89 | comments | search comments, no match | docs silent: 200 [] or 404 | HTTP 404 {"message":"No search results"} | PASS |
| 90 | comments | search comments without phrase | 4xx (phrase is required in docs) | HTTP 404 {"message":"Search must include a search [phrase]"} | PASS |
| 91 | comments | edit own comment | 200 + new body | HTTP 200 {"id":366,"commentable_id":58,"commentable_type":"App\\Models\\Topic","body":"Top level (edited)","status":"Ac... | PASS |
| 92 | comments | edit comment as non-author B | 403 | HTTP 403 {"message":"Only the comment's author, a moderator or an admin can change this comment."} | PASS |
| 93 | comments | edit comment with empty body | 422 | HTTP 422 {"message":"The body field is required."} | PASS |
| 94 | comments | edit unknown comment | 404 | HTTP 404 {"message":"Comment not found (99999999)"} | PASS |
| 95 | comments | delete comment as non-author B | 403 | HTTP 403 {"message":"Only the comment's author, a moderator or an admin can delete this comment."} | PASS |
| 96 | comments | delete comment without token | 401 | HTTP 401 {"message":"Unauthorized. Log in and send the header \"Authorization: Bearer <token>\"."} | PASS |
| 97 | votes | upvote topic without token | 401 | HTTP 401 {"message":"Unauthorized. Log in and send the header \"Authorization: Bearer <token>\"."} | PASS |
| 98 | votes | upvote topic with NO JSON body (what a naive client sends) | 200 (docs show no body) | HTTP 422 {"message":"POST values must be submitted in JSON format."} | FAIL |
| 99 | votes | upvote topic as B with {} | 200 + votes (docs: integer "votes") | HTTP 200 {"points":"1"} | FAIL |
| 100 | votes | upvote the same topic again as B (repeat) | 200 or 4xx; record behaviour | HTTP 200 {"points":"1"} | PASS |
| 101 | votes | topic score after repeat | score 1 (one vote per user) | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"Edited post","url":nul... | PASS |
| 102 | votes | downvote the same topic as B (switch) | 200 | HTTP 200 {"points":"-1"} | PASS |
| 103 | votes | topic score after switch | score -1 | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"Edited post","url":nul... | PASS |
| 104 | votes | downvote again as B (repeat/remove?) | 200 or 4xx; record behaviour | HTTP 200 {"points":"-1"} | PASS |
| 105 | votes | topic score after second downvote | score -1 or 0 (docs have no remove call) | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"Edited post","url":nul... | PASS |
| 106 | votes | upvote own topic as A | 200 or 403 (docs silent) | HTTP 200 {"points":0} | PASS |
| 107 | votes | upvote comment as B | 200 | HTTP 200 {"points":"1"} | PASS |
| 108 | votes | comment score after upvote | score 1 | HTTP 200 {"id":366,"commentable_id":58,"commentable_type":"App\\Models\\Topic","body":"Top level (edited)","status":"Ac... | PASS |
| 109 | votes | upvote own comment as A | 200 or 403 (docs silent) | HTTP 200 {"points":"2"} | PASS |
| 110 | votes | upvote unknown topic | 404 | HTTP 404 {"message":"Topic 99999999 does not exist.  Vote on Topic Failed."} | PASS |
| 111 | votes | upvote with bad {type} | 4xx | HTTP 404 {"message":"Invalid type Forum.  Upvote failed."} | PASS |
| 112 | reports | report topic without token | 401 | HTTP 401 {"message":"Unauthorized. Log in and send the header \"Authorization: Bearer <token>\"."} | PASS |
| 113 | reports | documented route POST /{type}/{id}/reports | 200 per docs | HTTP 404 {"message":"Not a valid api route - not found."} | FAIL |
| 114 | reports | report topic via /reports/type/topic/{id} (route the app uses) | 200 | HTTP 200 {"type":"Offensive","author_id":"31","status":"Pending Review","created_at":"2026-10-31T21:27:11.000000Z","id"... | PASS |
| 115 | reports | report comment with type "Other" | 200 | HTTP 200 {"type":"Other","author_id":"31","status":"Pending Review","created_at":"2026-10-31T21:27:13.000000Z","id":41} | PASS |
| 116 | reports | report with type "Spam" | 200 or 422 (docs do not list types) | HTTP 422 {"message":"The selected type is invalid."} | PASS |
| 117 | reports | report with type "Harassment" | 200 or 422 (docs do not list types) | HTTP 422 {"message":"The selected type is invalid."} | PASS |
| 118 | reports | report with type "Inappropriate" | 200 or 422 (docs do not list types) | HTTP 422 {"message":"The selected type is invalid."} | PASS |
| 119 | reports | report without type | 422 | HTTP 422 {"message":"The type field is required."} | PASS |
| 120 | reports | report unknown topic | 404 | HTTP 404 {"message":"topic 99999999 does not exist.  Report on topic Failed."} | PASS |
| 121 | reports | report the same topic twice as B | 200 or 4xx; record behaviour | HTTP 409 {"message":"You have already reported this topic."} | PASS |
| 122 | reports | GET /reports (documented) as normal user | 403 or 200 | HTTP 404 {"message":"Not a valid api route - not found."} | FAIL |
| 123 | reports | a reported topic still shows its own body and status | docs silent: record behaviour | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"This content has been ... | PASS |
| 124 | reports | topic lists the report in `reports` | 200 + non-empty reports | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"This content has been ... | PASS |
| 125 | reports | delete the report as its author (B) | 200 | HTTP 200 {"message":"Report deleted (40)"} | PASS |
| 126 | reports | delete the comment report while the comment still exists | 200 | HTTP 200 {"message":"Report deleted (41)"} | PASS |
| 127 | reports | topic body is restored after the report is deleted | body "Edited post", status Active | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"Edited post","url":nul... | PASS |
| 128 | delete | delete topic as non-author B | 403 | HTTP 403 {"message":"Only the topic's author, a moderator or an admin can delete this topic."} | PASS |
| 129 | delete | delete unknown topic | 404 | HTTP 404 {"message":"Topic not found (99999999)"} | PASS |
| 130 | delete | delete own comment c1 (has 11 nested replies) | 200 | HTTP 200 {"message":"Comment deleted (366)"} | PASS |
| 131 | delete | replies are gone with their parent (cascade) | 200 + comments [] | HTTP 200 {"id":58,"forum_id":51,"title":"Topic one yisrzcsj","slug":"topic_one_yisrzcsj","body":"Edited post","url":nul... | PASS |
| 132 | delete | GET deleted comment | 404 | HTTP 404 {"message":"Comment 366 not found."} | PASS |
| 133 | delete | delete the same comment twice | 404 | HTTP 404 {"message":"Comment not found (366)"} | PASS |
| 134 | delete | delete own topic | 200 | HTTP 200 {"message":"Topic deleted (58)"} | PASS |
| 135 | delete | GET deleted topic | 404 | HTTP 404 {"message":"Topic topic_one_yisrzcsj not found."} | PASS |
| 136 | logout | logout without token | 401 | HTTP 401 {"message":"Unauthorized. Log in and send the header \"Authorization: Bearer <token>\"."} | PASS |
| 137 | logout | logout A | 200 | HTTP 200 true | PASS |
| 138 | logout | GET /users/me with the logged-out token | 401 | HTTP 401 {"message":"Invalid auth token. Log in again."} | PASS |
| 139 | logout | write with the logged-out token | 401 | HTTP 401 {"message":"Invalid auth token. Log in again."} | PASS |
| 140 | logout | logout again with the same token | 401 | HTTP 401 {"message":"Invalid auth token. Log in again."} | PASS |
| 141 | logout | login again after logout | 200 + new token | HTTP 200 {"id":30,"name":"Sample A","email":"<email>","enabled":true,"admin":false,"token":"<redacted>","external_id":n... | PASS |
| 142 | users | forgot password for an unknown email | 200 or 404/422 (no code can be read here) | HTTP 200 {"message":"If an account exists for that email, a reset code has been sent."} | PASS |
| 143 | users | reset with a wrong code | 400 | HTTP 400 {"message":"Invalid or expired reset code."} | PASS |
| 144 | users | register/confirm with a wrong code | 400 or 422 | HTTP 400 {"message":"Invalid or expired code."} | PASS |
| 145 | users | delete user B as user A | 403 | HTTP 403 {"message":"Not authorized to delete user (31)"} | PASS |
| 146 | users | delete unknown user | 404 or 403 | HTTP 404 {"message":"User not found (99999999)"} | PASS |
| 147 | app client | ForumsApi.register | succeeds | id 32 | PASS |
| 148 | app client | ForumsApi.login | succeeds | ok | PASS |
| 149 | app client | ForumsApi.createForum | succeeds | forum 62 | PASS |
| 150 | app client | ForumsApi.listForums | succeeds | count 5 | PASS |
| 151 | app client | ForumsApi.createTopic | succeeds | topic 60 | PASS |
| 152 | app client | ForumsApi.listTopics | succeeds | count 1 | PASS |
| 153 | app client | ForumsApi.addComment | succeeds | comment 378 | PASS |
| 154 | app client | ForumsApi.addReply | succeeds | reply 379 | PASS |
| 155 | app client | ForumsApi.getTopic parses the tree | succeeds | comments 1, replies 1 | PASS |
| 156 | app client | ForumsApi.updateTopic | succeeds | edited text | PASS |
| 157 | app client | ForumsApi.updateComment | succeeds | edited comment | PASS |
| 158 | app client | ForumsApi.vote up (topic) | succeeds | points 1 | PASS |
| 159 | app client | ForumsApi.vote down (comment) | succeeds | points -1 | PASS |
| 160 | app client | ForumsApi.report (comment) | succeeds | ok | PASS |
| 161 | app client | ForumsApi.deleteComment | succeeds | ok | PASS |
| 162 | app client | ForumsApi.addComment with empty body -> 422 | ApiException 422 | ApiException 422: The body field is required. | PASS |
| 163 | app client | ForumsApi.deleteTopic | succeeds | ok | PASS |
| 164 | app client | ForumsApi.deleteForum | succeeds | ok | PASS |
| 165 | app client | ForumsApi.logout | succeeds | ok | PASS |
| 166 | app client | ForumsApi.listTopics on a deleted forum -> 404 | ApiException 404 | ApiException 404: Forum client_check_60qa5 does not exist. | PASS |
| 167 | cleanup | forums left after cleanup | same count as before the run (2) | HTTP 200, 2 forum(s) | PASS |

### Checks from earlier runs, not repeated in the table

These were seen in earlier runs of the same script or in manual probes with
`curl`, and are left out of the final run on purpose (see "Cleanup leftovers"):

- `DELETE /api/reports/{id}` answers `500 {"message":"Server Error"}` when the
  reported comment was deleted first. Seen for reports 29, 30, 33, 38 and 39
  (and once more in a run that crashed before writing results). The same call
  answers `200` while the comment still exists (rows above). The script runs
  this case only with `--orphan-report`, because every run adds a report that
  can never be removed.
- `GET /api/comments/search?phrase=level` and `phrase=Top level` answer `500`;
  `phrase=Top` and `phrase=original` answer `200`. (Rows above cover two of
  these.)
- Deleting a user does not delete their forums: a probe user's two forums
  survived the user, and nobody but an admin can delete them any more.
- `GET /api/forums/{slug}` with an unknown slug says `Topic <slug> not found.`
  (the message names the wrong resource).
- Percent-encoded slugs: `caf%C3%A9_au_lait`, `a%26b`, `what_is_this%3F`,
  `100%25_sure`, `slash%2Finside` and the double-encoded `caf%25C3%25A9_x` all
  answer `404`; the same slug sent with punctuation that needs no encoding
  (`bob's_(best)_forum!`, `dots,_dash-es_and_'quotes'_(ok)!_ok.`) answers `200`.
  The 404 message echoes the still-encoded text, so the path is not decoded
  before the lookup.

## App bugs (fixed)

Found while testing the app against the live API; each has a test.

1. **Creating a topic without text failed with 422.** The docs list `body` as
   optional for topics, the first draft of the form made it optional, and the
   API answers `422 The body field is required.` The form now requires text and
   `ForumsApi.createTopic` takes a required `body`.
2. **Slugs were percent-encoded twice** (`Uri.encodeComponent` and then
   `Uri.https`), so even punctuation the API can look up (`'`, `(`, `!`, `,`)
   became unreachable. The client now passes the slug through once.
3. **Forums and topics with accents, emoji, `?`, `%`, `#` or `/` in the title
   could be created but never opened** (the API does not url-decode path
   segments, see below). The new forum / new topic forms now refuse such titles
   with a plain explanation (`titleIsLookupSafe`). This is a workaround for an
   API bug, not a fix of it.
4. **The vote message was wrong.** It said "Your vote counts as N", but the API's
   `points` is the content's new *total* score, not the caller's vote. It now
   says "Vote counted. The score is now N."
5. **Reported content looked broken.** The API replaces the text of reported
   topics and comments with "This content has been reported and is pending
   moderation." The app now shows a "Reported: pending moderation" chip next to
   it.
6. **A 403 was always explained as "only the author can change this".** The forum
   limit is also a 403 ("Maximum number of forums (3) per developer account has
   been reached"). The friendly text is now generic and followed by the API's
   own message.

Learned before the first widget tests and built in from the start: votes send
`{}` as the JSON body (an empty POST is a 422), reports use
`/api/reports/type/{type}/{id}`, forum/topic/comment `status` is the
capitalised `Active`, topic `type` is `Post`, and report types are limited to
`Offensive` and `Other`.

## API bugs or doc mismatches (not fixed)

These are the API's behaviour, not the app's. I have no access to the API
source, so causes below are inferences from outside.

**The 10 FAIL rows**

1. `DELETE /api/forum/{id}` (singular, as documented) answers `404 Not a valid
   api route`. `DELETE /api/forums/{id}` works and is what the app uses.
2. + 3. **Topic `body` is required** on create (`422 The body field is
   required.`, also for an empty string) although the docs list only `title`,
   `status` and `type` as required.
4. + 5. `GET /api/comments/search` answers **500 `Server Error`** for some
   phrases (a phrase with a space, and the single word `level`) while other
   phrases work. The response gives no detail.
6. **Votes without a JSON body answer `422 POST values must be submitted in JSON
   format.`** The docs show no request body for the vote endpoints.
7. **The vote answer is `{"points":"1"}`** (a string, and once the number `0`),
   not `{"votes": <integer>}` as documented. `points` is the content's new
   total score. Repeating a vote changes nothing, and there is no call to take
   a vote back.
8. The documented report route `POST /api/{type}/{id}/reports` answers `404`.
   The route that works is `POST /api/reports/type/{type}/{id}` (the one the
   old Laravel clients use).
9. `GET /api/reports` (documented) answers `404`. (A normal user was expected to
   get `403` or a list.) Because of this, and because moderator/admin
   routes were not tested, report review was not exercised.
10. **Forum limit.** The docs say 3 forums per basic account. The API does
   enforce *a* limit, with `403 Maximum number of forums (3) per developer
   account has been reached. (Basic Acct)`, but not at 3: in the final run it
   fired when the key already held 7 forums (counting the 2 orphans below); an
   earlier run on an empty key accepted 8 live forums before refusing the 9th.
   I could not work out the rule.

**Other differences found (rows that pass because the docs are silent)**

- **Slug lookup does not url-decode.** Titles become slugs (lower case, spaces
  to `_`, other characters kept, e.g. `café_au_lait`, `smile_😀`, `why?`,
  `100%`). Reading a forum or topic whose slug needs percent-encoding to travel
  in a URL answers `404` forever (rows under "slugs"). Such forums can be
  created but not opened by slug, and there is no numeric-id route
  (`GET /api/forums/{id}` and `GET /api/topics/{id}` answer 404 for ids).
- **Reporting rewrites the content.** After a report, every `GET` (the author's
  included) shows `body` = "This content has been reported and is pending
  moderation." and `status` = "Pending Review"; deleting the report restores
  the original text (checked).
- **`DELETE /api/reports/{id}` answers 500** when the reported comment is already
  gone (see "Checks from earlier runs"); such reports can never be removed.
- **Deleting a user leaves their forums behind** (and nobody but an admin can
  delete them).
- **Logging in again invalidates the user's earlier token** (the token from
  register stopped working after a login). Only one token per user is live.
  Undocumented, and it will log a user out of other tabs/devices.
- `GET /api/users/me` returns the user's bearer token in the response body.
- A key sent only in an `apikey` HTTP **header** is accepted too; the docs
  describe only the query parameter.
- The docs list `title` as required for creating a comment (and for rules);
  creating a comment without a title works, `status` is what is required.
  Valid `status` values, topic `type` values and report types are not
  documented. By trial: `status` `Active` works (`published`, `open`, `public`,
  `enabled`, `draft` and `zzz` are `422`; the old clients also use `Draft`,
  `Pending Review` and `Locked`, which I did not try); topic `type` `Post` works
  (`Poem` is `422`; the old clients also use `Video`, `Url`, `Image`, not tried);
  report types: only `Offensive` and `Other` were accepted (`Spam`, `Harassment`,
  `Inappropriate`, `Hate` and `offensive` are `422`).
- Duplicate registration answers `400`, not `409`/`422`. Searching topics or
  comments without `phrase` answers `404`, not `422`. A search with no match
  answers `404 No search results`.
- Voting on your own topic or comment is allowed.
- Two topics with the same title in one forum are allowed; the second slug gets
  a `_1` suffix.
- The login failure message echoes the email that was sent
  (`Login Failed (<email>)`).
- The `422` for a topic over 4096 characters is `The body must not be greater
  than 4096 characters.`; nothing in the docs gives the limit.

### A note on `body` and Carbon

A prior team note said old Forums logs show errors involving a `body` field.
Every response body in every run was scanned for `Carbon`, `could not be
parsed`, `Trailing data` and `Unexpected data found`, and any `4xx` message
mentioning `body`. **None mentioned Carbon or a date.** What I saw involving
`body`:

- `422 The body field is required.` for topic create/edit and comment
  create/edit (also for whitespace-only comment text), including topics created
  without text, against the docs;
- `422 The body must not be greater than 4096 characters.`;
- the reported-content rewrite of `body` described above.

The two `500 Server Error` cases (comment search, deleting a report whose comment
is gone) return only `{"message":"Server Error"}`, so whether they are related to
the old `body`/date errors cannot be told from outside. They would be the first
place to look in the server log.

## Cleanup leftovers

Everything the script creates is deleted at the end (reports first, then
comments, topics, forums, and the test users last). What could not be removed:

- **Two forums, `limit probe` (id 38) and `limit probe 2` (id 39)**, created by
  me in a manual probe whose user I deleted before deleting its forums. The
  API then refuses everyone else (`403 Only the forum's author, a moderator or
  an admin can delete this forum.`). **The demo key was supposed to have no
  forums; it now has these two.** The key owner can remove them with the admin
  account (register with the key owner's email, confirm the emailed code, then
  `DELETE /api/forums/38` and `/39`).
- **A few orphan report rows** (ids 29, 30, 33, 38, 39, plus one more from a
  crashed run) that return `500` when deleted. They are not listed by any
  endpoint a normal user can call.

The final run's last row checks that the key holds exactly the forums it held
before the run (2, the orphans above).

## Not tested and why

- **Moderators, rules, tags** (`/forums/{id}/moderators`, `/moderators/{id}`,
  `/forums/{id}/rules`, `/rules/{id}`, `/forums/{id}/tags`, `/tags/{id}`) and
  **report review** (`PUT /api/reports/{id}`): need a moderator or the admin
  account, and the app does not use them.
- **Admin flows**: `GET /api/users` success and deleting other users need the
  admin, whose email is the one the key belongs to, which I do not control.
  `POST /api/users/register/confirm` happy path needs the emailed code.
  Only the normal-user `403` / wrong-code `400` answers were checked.
- **Password reset happy path** (`/users/forgot`, `/users/reset`): needs the
  emailed code; only an unknown email and a wrong code were checked.
- **Bulk deletes** (`DELETE /forums/`, `/forums/{id}/topics`, `/comments/{type}/{id}`
  and the moderator/rule equivalents): destructive for everyone using the key.
- **External auth mode** (key pointed at an auth service, where register/login
  answer `409`) and **secure-mode keys** (`APIKEY` header): need changes to the
  key's settings. The app's `409` handling is only covered by mocked tests.
- **`429` back-off**: never triggered at about one request per second.
- **Pagination, large lists, tags in topic search, topic types `Video`, `Url`
  and `Image`, statuses other than `Active`**: not exercised.
- **Concurrency** (two clients voting at once) and **other browsers**: only a
  headless Chromium load of the built app (it rendered the forum list from the
  live API without console errors) was done, not a scripted click-through.
