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
| Calls from a browser (CORS) | Only when `APP_ENV` is `development`, and only from this computer (`localhost`, `127.0.0.1`), so that Flutter web in Chrome can call the API. Never sent in `testing`, `staging` or `production`. The iPhone app does not need it. | Built |
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
- `retry_after_seconds` appears only when the app can be told how long to wait. Today
  that is `too_many_codes` only. The same number is sent in the header `Retry-After`.
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
| 404 | `verification_not_found` | The `verification_id` is unknown, belongs to another phone number, or its request is finished. | Start again: ask for a new code without the id. | Built |
| 404 | `user_not_found` | The access token is valid but its user does not exist. | Sign in again. | Built |
| 405 | `method_not_allowed` | Wrong HTTP method for this URL. | Fix the request. | Built |
| 422 | `validation_error` | The JSON is valid but a field is missing, has the wrong type, or is unknown. For the phone number, the code and the names, the detail code says why (section 5). | Fix the request or show the field error. | Built |
| 422 | `invalid_code` | The code is not correct. One of the 3 tries is used. | Show "wrong code". | Built |
| 422 | `code_expired` | The code is older than 300 seconds. No try is used. | Offer to send a new code (a resend). | Built |
| 422 | `code_already_used` | The request is finished: its code was accepted before. | Start again. | Built |
| 429 | `too_many_attempts` | The request used its 3 wrong tries. | Tell the user; start a new request. | Built |
| 429 | `too_many_codes` | 3 codes were already sent to this phone number in the last hour. Carries `retry_after_seconds`. | Show how long to wait. | Built |
| 500 | `internal_error` | An unexpected error on the server. | Show a general error. Keep the `request_id`. | Built |
| 503 | `sms_unavailable` | The SMS provider could not send or check the code. Nothing was counted. | Show "try again". | Built |

Every 401 also carries the header `WWW-Authenticate: Bearer`.

Tests: `tests/test_errors.py`, `tests/test_validation.py`, `tests/test_sign_in.py`.

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

### POST /api/v1/auth/request-code

Feature F01 (TFQD-13, TFQD-35). No access token. Sends a sign-in code by SMS and
answers with a `verification_id`. The names of the three sign-in endpoints and of
their fields are a proposal (**To confirm**) until the app has used them.

Body:

```json
{ "phone": "+966501234567" }
```

To send the code again inside the same request (a resend), add the id from the
first answer:

```json
{ "phone": "+966501234567", "verification_id": "10648d8694f64637be154c66408900ba" }
```

200:

```json
{ "verification_id": "10648d8694f64637be154c66408900ba" }
```

| Rule | Contract | Label |
|---|---|---|
| Phone number | `+966`, then 9 digits that start with 5 (`+9665XXXXXXXX`), English digits only. The app builds it from what the user types. Anything else is 422 `validation_error` with the detail code `invalid_phone`, and no SMS is sent. | Built |
| New request | Without `verification_id` a new request starts, with its own 3 tries. | Built |
| Resend | With `verification_id` another SMS is sent for the same request. The wrong tries already used stay used. | Built |
| Codes per phone number | At most 3 SMS per phone number in any 60 minutes. A resend is an SMS. The 4th is refused with 429 `too_many_codes` and nothing is sent. `retry_after_seconds` (and the header `Retry-After`) says how long to wait: until the oldest SMS of the hour is one hour old. | Built |
| Request without tries | A resend into a request that already used its 3 wrong tries is refused with 429 `too_many_attempts`. Nothing is sent. The app starts a new request. | Built |
| Same answer for every number | A phone number with an account and one without get the same answer, so the answer does not tell whether an account exists. | Built |
| The provider fails | 503 `sms_unavailable`. A send that failed is not counted in the limit of 3, and a request that only had that send is removed. | Built |

Errors: 400 `invalid_json`, 404 `verification_not_found`, 422 `validation_error`,
429 `too_many_codes`, 429 `too_many_attempts`, 503 `sms_unavailable`.

Real answers:

```
POST /api/v1/auth/request-code   {"phone": "0501234567"}
-> 422  validation_error, details: [{"field": "phone", "code": "invalid_phone", ...}]

4th code in one hour
-> 429  too_many_codes, "retry_after_seconds": 3239, header Retry-After: 3239
```

### POST /api/v1/auth/verify-code

Feature F01. No access token. Checks the code of a request. If it is right, the
server finds the user of the phone number (and creates it the first time) and
starts a session. The phone number is not sent again: the server takes it from the
request, so a code cannot be checked against another number.

Body:

```json
{ "verification_id": "10648d8694f64637be154c66408900ba", "code": "123456" }
```

200:

```json
{
  "access_token": "<access token>",
  "access_token_expires_at": "2026-10-15T12:15:00+00:00",
  "refresh_token": "<refresh token>",
  "refresh_token_expires_at": "2026-11-14T12:00:00+00:00",
  "user": {
    "id": "1840809a6c1b4814b9d1ecc779b8241b",
    "phone": "+966501234567",
    "first_name": null,
    "last_name": null,
    "display_name": null,
    "profile_complete": false
  }
}
```

| Rule | Contract | Label |
|---|---|---|
| Format of the code | 6 digits. Arabic-Indic and Persian digits are turned into 0 to 9, and the spaces at both ends are removed. Anything else is 422 `validation_error` with the detail code `invalid_code_format`. Nothing is checked and no try is used. | Built |
| Wrong code | 422 `invalid_code`. One of the 3 tries is used. | Built |
| After 3 wrong tries | The request accepts nothing, not even the right code: 429 `too_many_attempts`. Authentica is not called. The app starts a new request. | Built |
| Expired | If the code is refused and the last SMS of the request was sent more than 300 seconds ago: 422 `code_expired`. No try is used, because a user cannot type a right code that has expired. The app offers a resend. | Built |
| Used once | After a right code the request is finished. Checking it again is 422 `code_already_used`. Authentica is not called. | Built |
| The provider fails | 503 `sms_unavailable`. No try is used. | Built |
| The session | `access_token`, `refresh_token` and their times are those of section 4. | Built |
| Who is new | `user.profile_complete` is `false` until the profile is saved. The app shows the profile page when it is `false`. This also covers a user who left before saving it. | To confirm |

Errors: 400 `invalid_json`, 404 `verification_not_found`, 422 `validation_error`,
422 `invalid_code`, 422 `code_expired`, 422 `code_already_used`, 429
`too_many_attempts`, 503 `sms_unavailable`.

Real answers:

```
wrong code                 -> 422  invalid_code
code "12ab"                -> 422  validation_error, details: [{"field": "code", "code": "invalid_code_format", ...}]
same request after success -> 422  code_already_used
after 3 wrong tries        -> 429  too_many_attempts
301 seconds after the SMS  -> 422  code_expired
```

### PUT /api/v1/users/me/profile

Feature F01, the page after the first sign-in. Needs a valid access token. Saves
the three names of the user that the token belongs to and replaces the earlier
values. It is `PUT` because the app sends all three names every time.

Body:

```json
{ "first_name": "Leen", "last_name": "Algraawi", "display_name": "Leen" }
```

200:

```json
{
  "user": {
    "id": "e50f735fdbb54d0bafb5e2a0e54570d8",
    "phone": "+966501234567",
    "first_name": "Leen",
    "last_name": "Algraawi",
    "display_name": "Leen",
    "profile_complete": true
  }
}
```

| Rule | Contract | Label |
|---|---|---|
| Own profile | The user comes from the access token. There is no user id in the URL or the body, and an extra field is an error. | Built |
| `first_name`, `last_name` | 1 to 50 characters after the spaces at both ends are removed. | To confirm |
| `display_name` | 1 to 30 characters, the same way. | To confirm |
| One line | A name cannot contain a line break or another control character (detail code `invalid_name`). | To confirm |

Errors: 400 `invalid_json`, 401 (`missing_token`, `invalid_token`,
`access_token_expired`, `session_revoked`), 404 `user_not_found`, 422
`validation_error`.

### What F01 needs from the database (for TFQD-7)

Today the users, the sessions and the code requests are kept in memory, behind
three interfaces: `UserStore` (`app/users/store.py`), `SessionStore`
(`app/auth/store.py`) and `OtpStore` (`app/auth/otp_store.py`). The PostgreSQL work
replaces the in-memory classes with classes that follow the same interfaces.

- `tests/test_user_store.py` and `tests/test_otp_store.py` use only the interface, so
  the same tests must pass for the new classes: add them to the `STORES` list at
  the top of each file.
- `SessionStore` has no test file of its own. `tests/test_sessions.py` tests it
  through the API, so the same tests must pass once the app is given the new class.
- The code of the SMS is never stored.

**The tables (To confirm).** They follow the team's ER diagram (updated on 20 October
2026): the entities USER, AUTH_SESSION, VERIFICATION_REQUEST and VERIFICATION_SMS.
The code uses older names; the new classes map them: `phone` is `phone_number`,
`OtpRequest` is a row of `verification_requests`, `OtpSend` is a row of
`verification_sms`. Other columns of the ER, such as `app_mode`, are not used by F01.

| Table | Columns | Notes |
|---|---|---|
| `users` | `id` (uuid, primary key), `phone_number` (unique, not null, international format), `first_name`, `last_name`, `display_name` (all three null until the profile page is saved), `created_at` | One row per phone number. A check: the three names are all null or all filled. The user is created when the phone number is verified, which is before the profile page, so the names cannot be `NOT NULL`. `profile_complete` is not a column: the app works it out from the three names. `get_or_create_by_phone` must give one user when two requests arrive at the same time: use `INSERT ... ON CONFLICT (phone_number) DO NOTHING`, then read. |
| `auth_sessions` | `id` (uuid, primary key), `user_id` (references `users`, delete with the user), `refresh_token_hash` (unique, not null, SHA-256 in hexadecimal, 64 characters), `created_at`, `refresh_expires_at` (not null), `revoked_at` (null until sign-out) | One row per sign-in. Exactly these columns: by decision no device and no IP address is stored (a test checks the record). The unique key on `refresh_token_hash` is also the index for `POST /api/v1/auth/refresh`. Deleting a user deletes the sessions, which is the rule of section 4. |
| `verification_requests` | `id` (uuid, primary key; it is the `verification_id` of the API), `phone_number` (not null, international format, no foreign key), `created_at`, `wrong_tries` (integer, default 0, not less than 0), `verified_at` (can be null) | One row per verification request. No foreign key to `users`, because the request starts before the user exists. The limit of 3 wrong tries is not a database check: it comes from the configuration. |
| `verification_sms` | `id` (uuid, primary key), `request_id` (references `verification_requests`, delete with it), `phone_number`, `sent_at` | One row per SMS. Index on (`phone_number`, `sent_at`). `phone_number` is the same as in the request; a composite foreign key (`request_id`, `phone_number`) can make the database enforce it. |

**Times are written by the app (Built).** Every store method that writes a time
receives it as an argument (`now` or `at`), so the tests can move the clock. The
new classes store that value. A column default such as `now()` is only a fallback;
if it were the only source, the tests that move time could not run against
PostgreSQL.

**Ids (To confirm).** Today the API returns ids as 32 characters without hyphens
(`uuid4().hex`). A PostgreSQL `uuid` is written with hyphens. TFQD-7 picks one
format and the new classes convert it at the edge, so that an id has the same
form in the token, the responses and the tests.

**Table and column names.** `user` is a reserved word in PostgreSQL, so the table is
`users`.

Four operations must be correct when two requests arrive at the same time:

- `claim_send`: count the sends of the phone number in the last hour and insert the
  new one in the same transaction, with a lock for that phone number (for example
  `pg_advisory_xact_lock(hashtext(phone_number))`). Otherwise two requests can both
  take the third place and the fourth SMS is sent. When the call has no request id,
  the new request and its first send are inserted in that same transaction, so a
  refused call leaves nothing behind.
- `release_send`: delete the send. If it was the last send of its request, delete
  the request too.
- `claim_try`: `UPDATE verification_requests SET wrong_tries = wrong_tries + 1 WHERE
  id = ... AND wrong_tries < :max RETURNING ...`. No row returned means no tries
  left. `release_try` is the same update with `- 1` and `AND wrong_tries > 0`.
- `mark_verified`: `UPDATE ... SET verified_at = ... WHERE id = ... AND verified_at IS
  NULL`. No row returned means it was already finished.

Revoking a session is allowed twice and keeps the first time:
`UPDATE auth_sessions SET revoked_at = COALESCE(revoked_at, :at) WHERE id = ...`.
It returns False only when no row matches.

The phone number is personal data. Rows of `verification_requests` and
`verification_sms` older than 24 hours serve no purpose and can be deleted by a
cleanup job.

Tests: `tests/test_sign_in.py`, `tests/test_profile.py`, `tests/test_sessions.py`,
`tests/test_otp_store.py`, `tests/test_user_store.py`.

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

**How F01 uses it (Built, written with TFQD-13).** The endpoints are in section 5.

Sending a code (`request-code`):

1. The server checks the format of the phone number. A resend must name a request
   that exists, is open and belongs to this phone number.
2. The server takes one place in the limit of 3 codes per hour, in one step. If the
   count is already 3, it refuses and does not call Authentica. Taking the place and
   counting are one step, so two requests at the same time cannot both take the last
   place.
3. The server calls `send-otp` with `method` `sms`, `template_id` 5 and the phone
   number. It sends no `otp` field.
4. If the call fails, the place is given back, because no SMS was sent. A failed call
   is never counted.

Checking a code (`verify-code`):

1. The server turns Arabic-Indic digits (٠ to ٩) into 0 to 9, because an Arabic
   keyboard can type them, and checks that the code has 6 digits. A code that does
   not fit is refused before anything else and does not count as a try.
2. The server finds the verification request. An unknown id is refused. A request
   that is already finished is refused as `code_already_used`. Authentica is not
   called in either case.
3. The server takes one try, in one step. If the request already used 3, it refuses
   and does not call Authentica. The counters belong to the verification request, so
   a new code (a resend) does not reset them (TFQD-13).
4. The server calls `verify-otp`. The answer 200 with `status` true is a correct
   code: the server finishes the request, finds or creates the user of the phone
   number, and creates the session.
5. The answer 422 is a failure. The server chooses the message from its record of
   the sends: if more than 300 seconds passed since the last SMS of the request, the
   code is expired, and the try is given back; otherwise the code is wrong and the
   try stays used. Authentica still accepts or refuses the code. The record only
   chooses the message. The 300 seconds are a setting of the server
   (`OTP_VALID_SECONDS`), and they must equal the value in the dashboard.
6. If the sender raises `SmsDeliveryError`, the server answers that the service is
   not available (503) and gives the try back, because the code was not judged.

**Code in `app/sms` (Built, tested without a network).** `SmsSender` has two jobs:
`send_code(phone)` and `check_code(phone, code)`.

- `AuthenticaSmsSender` calls `send-otp` with `template_id` 5 and no `otp` field,
  and `verify-otp`. `check_code` answers `True` for HTTP 200 with `status` true, and
  `False` for HTTP 422. For anything else (a wrong key, the limit of 60 calls per
  minute, a server error, no answer, an answer it does not know) it raises
  `SmsDeliveryError`, because that is not a wrong try and must not be counted as one.
- `FakeSmsSender` makes and checks its own 6-digit code with the same rules: valid
  for `OTP_VALID_SECONDS` (300), accepted once, one answer for every refusal, and no
  block after wrong tries. It keeps only the latest code of a number. Whether
  Authentica does the same is test 9.
- Settings: `SMS_BACKEND` (`fake` or `authentica`), `AUTHENTICA_API_KEY`,
  `AUTHENTICA_TEMPLATE_ID` (5), `OTP_VALID_SECONDS` (300), `OTP_MAX_WRONG_TRIES` (3)
  and `OTP_MAX_SENDS_PER_HOUR` (3).
- The sign-in endpoints (section 5) call the sender that `SMS_BACKEND` selects.
- `scripts/try_authentica_sender.py` tries the real sender once, with one SMS.
  Not run yet (To confirm).

**OTP rules.** They come from TFQD-13 and TFQD-35, except the length of the code
and its validity, which were decided on 19 October 2026. The limit of 3 codes per
hour was confirmed on 18 October 2026.

| Rule | Value | Label |
|---|---|---|
| Code | 6 digits, made by Authentica (template 5) | **Decided** |
| Valid for | 300 seconds (5 minutes), set in the Authentica dashboard | **Decided** |
| Wrong tries | 3 per verification request, counted by our server (`OTP_MAX_WRONG_TRIES`) | TFQD-13 |
| Codes per phone number | At most 3 per hour (`OTP_MAX_SENDS_PER_HOUR`), a resend counts as a code | **Decided** |
| Counters | A new code for the same request (a resend) does not reset them | TFQD-13 |
| A new request | A request started without a `verification_id` has its own 3 tries. The limit of 3 codes per hour still counts every SMS, so at most 9 tries per hour per phone number. | To confirm |
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
6. `scripts/try_authentica_sender.py`, the first real call of the sender of the app, is
   not run yet (section 8).
7. Circle actions before the profile page is saved. A user exists after the first sign-in
   with no names, and the server does not force the profile page. If such a user accepts
   a circle request, the patient has a user without names. Either the server refuses
   circle actions until `profile_complete` is `true`, or every screen that shows a name
   handles a missing one. To decide with TFQD-7 and the circle features.

**Proposals written with the sign-in endpoints (To confirm).** Built and tested, but
the team has not reviewed them yet.

| # | Point | Proposal |
|---|---|---|
| A | Endpoint names | `POST /api/v1/auth/request-code`, `POST /api/v1/auth/verify-code`, `PUT /api/v1/users/me/profile` (section 5). |
| B | How long a verification request lives | Until its code is accepted. It has no time limit of its own: its counters never start again, and the code inside it lives 300 seconds. A new request (no `verification_id`) is always possible. This answers the old open point on when the counters start again. Rows older than 24 hours can be deleted (section 5). |
| C | A new request has new tries | A new request has its own 3 tries, but the 3 codes per hour are shared, so the most a phone number gets is 9 tries per hour. TFQD-13 says the limits do not reset "simply because a new OTP is issued"; here a resend does not reset them, only a request started from the beginning does. |
| D | An expired code is not a try | A refused code that arrives more than 300 seconds after the last SMS is `code_expired` and costs no try. |
| E | Phone number | Saudi mobile numbers only, `+9665XXXXXXXX`. |
| F | Names | 1 to 50 characters (first and last name), 1 to 30 (display name), one line. |
| G | Who sees the profile page | The app shows it when `user.profile_complete` is `false`. |
