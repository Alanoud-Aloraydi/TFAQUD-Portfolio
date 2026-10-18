# API contracts (TFQD-11)

Status: draft. The points marked **Decided** were decided by the project lead
on 18 October 2026. The team reviews them in the pull request.

This document fixes the rules that every endpoint follows, the endpoints that
exist today, and the authorization rules. Every example below was produced by
running the real code. The tests named in the tables check the rules.

Each statement carries one of these labels:

| Label | Meaning |
|---|---|
| **Built** | The code does this and a test checks it. |
| **Rule** | A rule written in TFQD-11. The code follows it where it applies. |
| **Decided** | Decided by the project lead (Leen Algraawi) on 18 October 2026. The team can ask for a change in the pull request review. |
| **To confirm** | A proposal. It is not decided yet. |
| **Open** | Not decided. Listed again in section 10. |

## 1. General conventions

| Topic | Contract | Label |
|---|---|---|
| Base path | Every endpoint starts with `/api/v1`. | Built |
| Format | Requests and responses are JSON. A request with a body sends `Content-Type: application/json`. | Built |
| Field names | `snake_case`. | Built |
| Times | ISO 8601 with the UTC offset, for example `2026-10-17T17:51:25.157463+00:00`. The server works in UTC. | Built |
| Request id | Every response has the header `X-Request-ID`. The app may send its own value (1 to 64 letters, digits, `_` or `-`); any other value is replaced. Every error body repeats the id as `request_id`. Send it with a bug report. | Built |
| Unknown URL or wrong method | Returned in the error format (404 `not_found`, 405 `method_not_allowed` with an `Allow` header). | Built |
| Circle endpoints | The circle id is part of the path: `/api/v1/circles/{circle_id}/...`. | Rule |

## 2. Error format

Every error has this shape and nothing else:

```json
{
  "error": {
    "code": "validation_error",
    "message": "The request is not valid.",
    "request_id": "38b5066ad1b94e308b084de0dd98595c",
    "details": [
      { "field": "refresh_token", "code": "missing", "message": "Field required" }
    ]
  }
}
```

- The app acts on `code`, which does not change. It shows its own Arabic text.
- `message` is English, for developers and logs. It is not shown to the user.
- `details` appears only for `validation_error`.
- A 500 never contains a traceback or any internal detail.

| Status | `code` | When | What the app does | Label |
|---|---|---|---|---|
| 400 | `invalid_json` | The body is missing, is not JSON, or the content type is wrong. | Fix the request (a bug in the app). | Built |
| 401 | `missing_token` | No `Authorization: Bearer <token>` header. | Sign in. | Built |
| 401 | `invalid_token` | The access token is damaged, forged, or of the wrong kind. | Sign in again. | Built |
| 401 | `access_token_expired` | The access token is valid but past its time. | Refresh once, then repeat the request once. | Built |
| 401 | `session_revoked` | The session was ended by sign-out, or does not exist. | Sign in again. | Built |
| 401 | `invalid_refresh_token` | The refresh token is unknown, expired, or its session was ended. | Sign in again. | Built |
| 403 | `forbidden` | The caller has no access to this circle (see section 6). | Show "no access". | Built |
| 404 | `not_found` | The URL does not exist. | Fix the request. | Built |
| 405 | `method_not_allowed` | Wrong HTTP method for this URL. | Fix the request. | Built |
| 422 | `validation_error` | The JSON is valid but a field is missing, has the wrong type, or is unknown. | Fix the request or show the field error. | Built |
| 500 | `internal_error` | An unexpected error on the server. | Show a general error. Keep the `request_id`. | Built |

Every 401 also carries the header `WWW-Authenticate: Bearer`.

Tests: `tests/test_errors.py`, `tests/test_validation.py`.

## 3. Validation

- Every request body is described by a class (a DTO) and checked on the server
  before any other logic runs. The app's own checks are never the only ones.
- A field that is not in the DTO is an error (`extra_forbidden`), not ignored.
  A typo in the app is found at once.
- Text fields lose the spaces at the start and the end.
- The error names the field and the kind of problem, and never repeats the
  value that was sent. A phone number or a code does not end up in a response
  or a log.

Examples (real output):

```
POST /api/v1/auth/refresh      {}
-> 422  validation_error, details: [{"field": "refresh_token", "code": "missing", ...}]

POST /api/v1/auth/refresh      {"refresh_token": "x", "foo": 1}
-> 422  validation_error, details: [{"field": "foo", "code": "extra_forbidden", ...}]

POST /api/v1/auth/refresh      hello   (Content-Type: text/plain)
-> 400  invalid_json
```

## 4. Authentication

The app sends the access token with every protected request:

```
Authorization: Bearer <access token>
```

| | Access token | Refresh token |
|---|---|---|
| What it is | A signed token (JWT, HS256) holding the user id, the session id and the expiry time | A random string with nothing inside |
| Lifetime | 15 minutes (**Decided**) | 30 days (**Decided**) |
| Sent to | Every protected endpoint | `POST /api/v1/auth/refresh` only |
| The server keeps | Nothing. It checks the signature and the session record. | Only the SHA-256 hash of it, in the session record |

**Sign-out rule (Rule).** Sign-out is done on the server. It ends the session,
and from that moment:

- the access token of that session is refused at once (`session_revoked`), even
  if its 15 minutes have not passed;
- the refresh token of that session is refused (`invalid_refresh_token`).

Signing out one session does not end the user's other sessions (**Decided**).
There is no endpoint that ends all the sessions at once, because no story asks
for it. Deleting an account (F05) ends every session of that user.

**Order of the checks on a protected request (Built).** First the signature,
then the expiry, then the session record. This is why an expired token gives
`access_token_expired` and a signed-out one gives `session_revoked`.

**The app's rule for 401 (Rule).** On `access_token_expired`: call refresh once,
then repeat the original request once. On any other 401 `code`: go to sign-in.

**A refresh does not replace the refresh token (Built, Decided).** The response
carries a new access token only. The same refresh token stays valid until day
30 or until sign-out. The reason: the users include older patients on weak
connections. If the answer of a refresh is lost on the way, a replaced token
would leave them signed out with no way back.

Tests: `tests/test_sessions.py`.

## 5. Endpoints that exist today

### GET /api/v1/health

No sign-in. Answers 200 while the server process runs. It does not check the
database yet.

```json
{ "status": "ok" }
```

### POST /api/v1/auth/refresh

No access token. Body:

```json
{ "refresh_token": "<the refresh token>" }
```

200:

```json
{
  "access_token": "<new access token>",
  "access_token_expires_at": "2026-10-17T17:51:25.157463+00:00"
}
```

Errors: 422 `validation_error`, 400 `invalid_json`, 401 `invalid_refresh_token`.

### POST /api/v1/auth/sign-out

Needs a valid access token. No body. Ends the session of that token.

204, empty body. Errors: 401 (`missing_token`, `invalid_token`,
`access_token_expired`, `session_revoked`).

### GET /api/v1/auth/session

Needs a valid access token. Tells the app who the token belongs to.

```json
{ "session_id": "23aa61a5d241485ca8b823c04b99c712", "user_id": "user-42" }
```

### Sign-in with the phone number and the code (F01)

Not built yet (TFQD-13, TFQD-35). When the code is verified the server creates
the session, and the session service already produces the four values the app
needs: `access_token`, `access_token_expires_at`, `refresh_token` and
`refresh_token_expires_at`. The request and the response of the sign-in
endpoints are written with F01, using the answers of TFQD-12 (section 8).

## 6. Authorization

**Roles (Rule).** A user has one of three roles in a circle: `manager`,
`patient` (uses the full app for themselves) or `simplified_patient` (uses
Simplified Mode). The role belongs to the pair (user, circle), not to the user.
The same person can be a manager in one circle and a patient in another.

**Selected circle (Rule).** Every circle endpoint takes the selected circle id
in the path. The server checks the caller's role in exactly that circle.

- The Today endpoint returns one circle only.
- V1.0 has no endpoint that merges several circles.
- **The bell is the one exception.** It returns the notifications of all the
  circles of the user. Its path is `GET /api/v1/notifications` (see below).

**How the server decides (Built).** For each circle endpoint the server asks
"what is this user in this circle?" and compares the answer with the roles the
endpoint allows.

| Situation | Answer |
|---|---|
| No valid token | 401 (the codes in section 2) |
| Member of the circle, role allowed | The endpoint runs |
| Member of the circle, role not allowed | 403 `forbidden` |
| Not a member of the circle | 403 `forbidden` |
| The circle does not exist | 403 `forbidden` |

The last three give the same answer on purpose, so that a caller cannot find out
which circles exist. The server also fails closed: until the membership lookup
is connected, nobody is a member of anything, so every circle endpoint refuses
every request.

**Authorization scenarios and the tests that check them**

| # | Scenario | Expected | Test (`tests/test_authorization.py`) |
|---|---|---|---|
| 1 | Member with an allowed role | 200 | `test_member_with_an_allowed_role_gets_in` |
| 2 | Member with a role the endpoint does not allow | 403 | `test_member_with_a_role_that_is_not_allowed_is_refused` |
| 3 | A role in one circle gives nothing in another | 403 | `test_role_in_one_circle_gives_nothing_in_another` |
| 4 | A different role in each circle is respected | 200 / 403 | `test_a_different_role_in_each_circle_is_respected` |
| 5 | Not a member, and unknown circle | Same 403 | `test_non_member_and_unknown_circle_get_the_same_answer` |
| 6 | Endpoint lists no roles | Any member gets in | `test_no_roles_listed_accepts_any_member` |
| 7 | Not signed in | 401, not 403 | `test_not_signed_in_is_401_not_403` |
| 8 | Signed out, but still a member | Refused | `test_signed_out_user_is_refused_even_if_still_a_member` |
| 9 | Nothing connected yet | Everybody refused | `test_default_circle_access_refuses_everyone` |

What each role may do in each feature is decided per feature. Section 7 lists
the roles that the user stories name.

### The bell (Decided, not built yet)

`GET /api/v1/notifications` returns the notifications of all the circles of the
signed-in user in one list (F15, TFQD-25). The path has no circle id: this is the
one exception to the selected-circle rule.

- It needs a valid access token. The server returns only the notifications
  addressed to that user, so no circle role is checked. A pending circle request
  is shown even when the user has no circle yet.
- Query: `limit` (1 to 50, default 20) and `cursor` (the `next_cursor` of the
  previous answer). The newest notification comes first.
- 200:

```json
{
  "items": [
    {
      "id": "...",
      "type": "circle_request",
      "circle_id": "...",
      "title": "...",
      "created_at": "2026-10-18T09:30:00+00:00",
      "read_at": null,
      "deep_link": "..."
    }
  ],
  "unread_count": 1,
  "next_cursor": null
}
```

| Field | Meaning |
|---|---|
| `id` | The id of the notification. |
| `type` | `circle_request`, `manager_invitation`, `care_alert` or `care_reminder`. Later features may add types. |
| `circle_id` | The circle it belongs to, or `null` when no circle exists yet. |
| `title` | The text to show. |
| `created_at`, `read_at` | UTC times. `read_at` is `null` while the notification is unread. |
| `deep_link` | Where the app goes when the user taps the notification. |
| `unread_count` | The number of unread notifications in all circles, not only in this page. |
| `next_cursor` | `null` on the last page. |

F15 may add fields. It does not rename or remove these.

`POST /api/v1/notifications/{notification_id}/read` marks one notification as
read and answers 204. An id that does not exist and an id that belongs to
someone else give the same 404 `not_found`, so that nobody can probe ids.

Accepting or declining a circle request, or an invitation, is part of the F02
contract. The notification only links to it.

## 7. Roles named in the user stories

Taken from the titles of the stories in Jira. This is the starting point for the
per-feature permission tables.

| Role named | Stories |
|---|---|
| Manager | TFQD-29 (US-02), TFQD-32 (US-18), TFQD-84 (US-04), TFQD-85 (US-05), TFQD-86 (US-26), TFQD-87 (US-07), TFQD-88 (US-09), TFQD-89 (US-11), TFQD-91 (US-14), TFQD-92 (US-06), TFQD-93 (US-08), TFQD-94 (US-23), TFQD-97 (US-16), TFQD-98 (US-20), TFQD-99 (US-21) |
| Manager or patient | TFQD-31 (US-10), TFQD-34 (US-24), TFQD-35 (US-29), TFQD-95 (US-28), TFQD-96 (US-13) |
| Patient (no mode named) | TFQD-30 (US-03), TFQD-33 (US-19) |
| Patient using Detailed Mode | TFQD-28 (US-01) |
| Patient using Simplified Mode | TFQD-90 (US-12) |

### The simplified patient, per story (Decided)

A circle role applies only to an action inside a circle. An action before any
circle exists, or on the user's own account, checks no circle role: every
signed-in user can do it, in any mode.

| Story | Action | Simplified patient |
|---|---|---|
| TFQD-30 (US-03) | Approve or decline a circle request | No role check. The request is addressed to the signed-in user, who has no role in that circle yet. |
| TFQD-31 (US-10) | Skip circle creation in onboarding | No role check. No circle exists yet. |
| TFQD-33 (US-19) | View the emergency card | **Yes**, read-only. Allowed roles: `patient`, `simplified_patient`. The story says Simplified Mode opens the card. |
| TFQD-34 (US-24) | Edit the account, sign out, request account deletion | No role check. These are account actions. |
| TFQD-34 (US-24) | Leave a circle | **No.** Only a manager can leave, with the rules of F03. The story describes only the Manager leaving. |
| TFQD-35 (US-29) | Sign in with the phone number and the code | No role check. It happens before any circle. |
| TFQD-95 (US-28) | Record an unscheduled reading | **Yes.** Allowed roles: `manager`, `patient`, `simplified_patient`. The story says Simplified Mode has the same capability. |
| TFQD-96 (US-13) | Receive care reminders | **Yes**, as the recipient. A reminder is addressed to the user, in either mode. |

## 8. Answers from TFQD-12 (Authentica)

Tested on 17 October 2026, between 23:25 and 23:38 (Riyadh), with
`scripts/authentica_probe.py` and one Authentica account. Each result below was
a real call; the SMS went to one Saudi mobile number. The sender-name call was
made on 18 October 2026, and the template 5 test on 19 October 2026. The test
steps are in `docs/authentica-test-guide.md`.

### The four questions

| Question | Answer | Label |
|---|---|---|
| Response format of `send-otp` and `verify-otp`, including errors | See the table "Response formats" below. | Built (tested) |
| How long a code stays valid | 300 seconds (5 minutes). The project lead set it in the Authentica dashboard, and Authentica enforces it. Before that setting, Authentica kept a code for at least 4 minutes 12 seconds (sent at 23:27:04, verified at 23:31:16). Not tested: that a code is refused after 300 seconds. | Decided |
| Does Authentica send our own code when the `otp` field is given | Not used. Authentica makes the code itself (`template_id` 5, 6 digits, Arabic text). In one test `verify-otp` accepted our own code `123456`, but we let Authentica make the code (see the decision below). The default template gives a code of 4 digits. | Decided |
| Which sender name the user sees | `authentica`. With the default template the text is in English and arrived in about 6 seconds; template 5 gives an Arabic text. A custom name is refused: a call with `sender_name` set to `TFAQUD` got 422 with the message "Sender name is not valid". A custom name must be registered with Authentica first. | Built (tested) |

### Response formats

| Call | HTTP | Body |
|---|---|---|
| Wrong or missing key | 401 | `{"errors": [{"message": "Unauthorized"}]}` |
| `GET /balance` | 200 | `{"success": true, "data": {"balance": "99"}, "message": "Balance retrieved successfully."}` (the balance is a string) |
| `POST /send-otp`, success | 200 | `{"success": true, "data": null, "message": "OTP sent successfully."}` |
| `POST /verify-otp`, success | 200 | `{"status": true, "message": "OTP verified successfully"}` |
| `POST /verify-otp`, wrong code | 422 | `{"status": false, "message": "Failed to verify OTP"}` |

- `send-otp` answers with `success`. `verify-otp` answers with `status`. Our code
  reads a different field for each.
- The message text differs from the documentation ("OTP send successfully"
  there). Our code decides from the HTTP status and the `success` or `status`
  field, never from the message text.
- A code of the wrong length (3 or 5 digits) gets the same 422 answer as a wrong
  code of the right length. There is no separate "bad format" answer.
- Every call carries `x-ratelimit-limit: 60` and `x-ratelimit-remaining`. A wrong
  try also uses one. The counter returned to 59 in the next minute, so the limit
  is 60 calls per minute (observed, not documented).

### Other results

- One SMS costs one credit (100 became 99).
- No block after wrong tries: 3 wrong tries, then the correct code verified. 4
  wrong tries on a second code, then the correct code verified.
- A code used a second time (template 5 test, 19 October 2026): it failed, as
  the project lead reported. The exact HTTP status and body are not recorded
  yet.
- A call with `sender_name` set to `TFAQUD`: 422, message "Sender name is not
  valid". The API knows the field, but accepts only a name that is registered
  for the application.
- `template_id` 5 (tested on 19 October 2026): the SMS text is in Arabic, the
  code has 6 digits, and the sender is `authentica`. The template has a place
  for the name of the application (`{{app_name}}`) and for the code
  (`{{otp}}`). The documentation gives only the default `1` and the examples
  `1` and `31`.

### Tests not run yet

Authentica checks the code, so these cases depend on Authentica. Each one needs
one real SMS. The steps are tests 8, 9 and 6 in `docs/authentica-test-guide.md`.

| Case | What to find out |
|---|---|
| An expired code | Send, wait 5 minutes and 10 seconds, verify. The code must be refused. This shows that the 300 seconds of the dashboard are applied, and gives the answer for an expired code. |
| Sending twice quickly | Whether the second send is refused, and whether the first code still works after the second send. |
| A phone number in the wrong format | Our server checks the number before it calls Authentica. The answer of Authentica for a number it cannot deliver to is recorded in the F01 tests. |
| The limit on `send-otp` calls | Our own limit (3 codes per phone number per hour) comes first. The limit of Authentica (60 calls per minute) is far above it. |

### Decision: Authentica makes and checks the code (Decided)

Decided by the project lead on 19 October 2026. Authentica makes the code with
`template_id` 5 (6 digits, Arabic text), sends the SMS, keeps the code for 300
seconds (a setting in the Authentica dashboard) and checks it with `verify-otp`.
Our server does the two jobs that Authentica does not do: it counts the wrong
tries and it limits the codes per hour.

| Job | Done by |
|---|---|
| Make the code (6 digits) and send the Arabic SMS | Authentica (`send-otp`, `template_id` 5) |
| Keep the code for 300 seconds | Authentica (dashboard setting) |
| Check the code, and accept it once | Authentica (`verify-otp`) |
| Stop after 3 wrong tries | Our server |
| At most 3 codes per phone number per hour | Our server |
| Check the format of the phone number before any call | Our server |
| Create the session after a correct code | Our server (section 4) |

Reasons from the tests:

- Authentica did not block any wrong try (7 wrong tries in total, and the correct
  code still worked). Only our server can enforce the rule of 3 wrong tries: it
  counts the tries and does not call `verify-otp` after the third wrong one.
- Template 5 gives an Arabic text and a 6-digit code without any work on our side.
- Our database never holds a code, not even its hash.
- A code used a second time was refused (template 5 test).

**What Authentica does not tell us.** A wrong code and a code of the wrong length
get the same answer: 422 `Failed to verify OTP`. The answers for an expired and a
used code are not recorded yet; if they are the same, Authentica cannot tell the
failures apart. TFQD-35 asks for different feedback for an incorrect, an expired, a
reused and an excessive-attempt code. Our server can tell them apart with its own
record of each send, as the steps below show.

**How F01 uses it (Proposal, written with TFQD-13).**

Sending a code:

1. The server checks the format of the phone number.
2. The server counts the codes sent to this number in the last hour. If the count
   is 3, it refuses and does not call Authentica.
3. The server calls `send-otp` with `method` `sms`, `template_id` 5 and the phone
   number. It sends no `otp` field.
4. After a success answer, the server records the send: the phone number and the
   time. A failed call is not counted, because no SMS was sent.

Checking a code:

1. The server checks that the code has 6 digits.
2. If the verification request already has 3 wrong tries, the server refuses and
   does not call Authentica. The counters belong to the verification request, so
   a new code does not reset them (TFQD-13).
3. The server calls `verify-otp`. The answer 200 with `status` true is a correct
   code: the server marks the send as verified and creates the session.
4. The answer 422 is a failure. The server chooses the message from its record of
   the send: the send was already verified, so the code is used; more than 300
   seconds passed since the send, so the code is expired; otherwise the code is
   wrong, and it counts as one wrong try. Authentica still accepts or refuses the
   code. The record only chooses the message. The 300 seconds are a setting of the
   server, and they must equal the value in the dashboard.

**Code in `app/sms`.** Today `SmsSender.send(to, message)` sends a message text.
F01 replaces it with an interface that has two jobs: send a code to a phone
number, and check a code. The fake version makes and checks its own 6-digit code,
so no test calls Authentica.

**OTP rules.** They come from TFQD-13 and TFQD-35, except the length of the code
and its validity, which were decided on 19 October 2026. The limit of 3 codes per
hour was confirmed on 18 October 2026.

| Rule | Value | Label |
|---|---|---|
| Code | 6 digits, made by Authentica (template 5) | **Decided** |
| Valid for | 300 seconds (5 minutes), set in the Authentica dashboard | **Decided** |
| Wrong tries | 3 per verification request, counted by our server | TFQD-13 |
| Codes per phone number | At most 3 per hour | **Decided** |
| Counters | A new code does not reset them | TFQD-13 |
| Not used | A device identifier, an IP address. No phone lock in V1.0. | TFQD-13 |

## 9. Definition of Done

**Shared (Rule, from TFQD-11).** An end-to-end feature is complete when Flutter,
Flask, PostgreSQL, permissions, automated tests and peer review integrate
successfully.

- Flutter: the existing Cleany structure is reused (a missing screen or module
  is generated only when appropriate); data, domain and presentation layers and
  the Cubit are implemented.
- Flask: the endpoints and the role checks are validated.
- PostgreSQL: migrations where needed.
- Automated tests are integrated, and a peer review is done.

**Checklist for a Flask endpoint (proposal).**

1. The path is under `/api/v1`, and a circle endpoint has `{circle_id}` in it.
2. The request body is a DTO (`app/validation.py`).
3. Errors use the format of section 2, with a stable `code`.
4. A circle endpoint uses `require_circle_role(...)` with the roles it allows.
5. Tests cover: success, an invalid body (422), no token (401), a role that is
   not allowed (403), and a user who is not a member (403).
6. No test sends a real SMS or opens a network connection.
7. A change in the contract is changed in this document in the same pull request.

## 10. Decisions and open points

**Decided on 18 and 19 October 2026 by the project lead.** The team can ask for a
change in the pull request review.

| # | Point | Decision |
|---|---|---|
| 1 | Token lifetimes | 15 minutes (access) and 30 days (refresh). Confirmed. |
| 2 | Refresh token replacement | Not replaced. The same token works until day 30 or sign-out (section 4). |
| 3 | Patients and Simplified Mode | Decided per story in section 7. |
| 4 | The bell endpoint | `GET /api/v1/notifications` and `POST /api/v1/notifications/{notification_id}/read` (section 6). |
| 5 | Who makes and checks the OTP code | Authentica, with template 5: a 6-digit code, Arabic text, valid 300 seconds (dashboard setting). Our server counts the 3 wrong tries (section 8). Decided on 19 October 2026. |
| 6 | Codes per phone number | At most 3 per hour (section 8). |
| 7 | Sign-out of all sessions (F05) | Not in V1.0, because no story asks for it. Sign-out ends one session. Deleting an account ends every session of the user (section 4). |

**Still open**

1. The answers of Authentica to record: the exact answer for a code used a second
   time (it failed in the template 5 test), and for a code after 300 seconds
   (not tested).
2. The answers of Authentica that the F01 tests record: a number it cannot deliver
   to, and sending twice quickly (whether the second code cancels the first).
3. The sender name: a custom name such as `TFAQUD` is refused until it is
   registered with Authentica (section 8). Until then the SMS comes from
   `authentica`.
4. The name of the application in the SMS: template 5 has a place for it
   (`{{app_name}}`). It must read TFAQUD. Check it in the real SMS.
5. TFQD-13 and TFQD-35 say a code of four digits. They must say six.
6. How long a verification request lives. A new code does not reset its counters
   (TFQD-13), but TFQD-13 does not say when the counters start again, for
   example after a correct code or after an hour. It is decided with F01.
