# TFAQUD backend

Flask REST API for the TFAQUD app. All endpoints are under `/api/v1`.

## Run it with Docker

You need Docker Desktop (or Docker Engine) with Compose v2. Check it first:

```
docker compose version
```

This must print a version. If it prints an error, see the table "If something
fails" below.

1. Copy the settings template and open the copy:

   ```
   cp .env.example .env
   ```

2. In `.env`, set `POSTGRES_PASSWORD` to a password you choose, using letters
   and digits only. Do not use `$`, spaces, quotes or `#`: Docker Compose reads
   `$name` in a `.env` file as a variable. The other values work as they are.
   `.env` is never committed (it is in `.gitignore`).

3. Start the API and the database:

   ```
   docker compose up --build
   ```

   The first time, the database is empty. The API container creates the tables
   by itself before the server starts (you will see lines that start with
   `Running upgrade`). Every later start checks again and changes nothing.

4. Check that it works. This should print `{"status":"ok"}`:

   ```
   curl http://localhost:5000/api/v1/health
   ```

Other commands:

| What | Command |
|---|---|
| Run the tests inside the container | `docker compose run --rm api pytest` |
| Stop everything | `docker compose down` |
| Stop and delete the database data | `docker compose down -v` |
| See the logs of the API | `docker compose logs -f api` |
| Create or update the tables by hand | `docker compose exec api flask --app wsgi db upgrade` |

Editing a file in `app/` reloads the server by itself.

### If something fails

| Message | Cause and fix |
|---|---|
| `unknown flag: --build`, or `'compose' is not a docker command` | The Compose plugin is missing, or Docker is not connected to your terminal. On Windows with WSL: open Docker Desktop, go to Settings, Resources, WSL Integration, enable your Linux distribution, press Apply, then open a new WSL terminal. On Linux: install the `docker-compose-plugin` package from Docker's apt repository. Then check again with `docker compose version`. |
| `env file .env not found` | Do step 1. |
| `Set POSTGRES_PASSWORD in the .env file` | Do step 2. |
| `The "..." variable is not set. Defaulting to a blank string` | A value in `.env` contains a `$`. Compose treats the text after it as a variable name. Change the value to letters and digits only. A `$` in the middle of a value silently cuts the value at that point. |
| `port is already allocated` or `address already in use` (port 5000) | On macOS, AirPlay Receiver uses port 5000. In `.env`, remove the `#` from `API_PORT=5000` and set another number, for example `5001`. Then use that number in the `curl` command. |
| `ports are not available` or `port is already allocated` (the database port, 5433 by default) | Another program uses that port. In `.env`, set `DB_PORT` to another number, for example `5434`. Then run `docker compose up` again. |
| `GET /api/v1/health` answers 503 `database_not_migrated` | The database is reachable, but its tables are missing or old. Run `docker compose exec api flask --app wsgi db upgrade`, or restart with `docker compose up`, which does it. |

## Run it without Docker

You need Python 3.10 or newer. The tests were run on Python 3.13.

```
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
flask --app wsgi run               # the API on http://127.0.0.1:5000
pytest                             # the tests
```

Without a `.env` file the app starts in the `development` environment with a
built-in secret key. This works on your computer only.

Without a database setting (`DATABASE_URL`, or `DATABASE_HOST` with the
`POSTGRES_*` values) the server keeps users and sessions in memory and the circle
endpoints answer 503 `service_unavailable`. To use PostgreSQL, set `DATABASE_URL`
(for example `postgresql+psycopg://user:password@localhost:5433/tfaqud`) and run
`flask --app wsgi db upgrade` once.

## Database and migrations

The tables are created by migrations (`migrations/versions/0001` to `0010`),
not by hand.

| What | Command |
|---|---|
| Create or update all tables | `flask --app wsgi db upgrade` (in Docker: `docker compose exec api flask --app wsgi db upgrade`) |
| Which version is the database at | `flask --app wsgi db current` |
| Go back one version | `flask --app wsgi db downgrade` |

A new, empty database has no tables. In Docker the API container runs the first
command before it starts the server. `GET /api/v1/health` answers 503
`database_not_migrated` when the tables are missing or old.

**Tests against PostgreSQL.** The tests in `integration_tests/` run the real
migrations and need a database whose name ends in `_test`. They are skipped when
`TEST_DATABASE_URL` is not set. They empty the tables of that database, so never
point it at a database that holds real data. With Docker:

```
docker compose exec db sh -c 'createdb -U $POSTGRES_USER tfaqud_test'
docker compose exec api sh -c 'TEST_DATABASE_URL=postgresql+psycopg://$POSTGRES_USER:$POSTGRES_PASSWORD@db:5432/tfaqud_test pytest'
```

The first command is needed once. The second runs all the tests, with the
PostgreSQL ones included.

## Demo data

To try the app with something in it, fill the local database with demo data:

```
docker compose exec api flask --app wsgi demo-data
```

It makes three demo accounts. Sign in on the phone with **0500000001**
(«لينا», the detailed mode) or **0500000004** («خالد», the simplified mode);
the code is in the API log (`docker compose logs api`, the line
`FAKE SMS ... Your code is ...`), or `DEMO_SIGN_IN_CODE` when it is set.
Lina's account has:

- «رعايتي», her own care, with two medicines;
- «دائرة نورة», her mother's care (no account), with every kind of medicine:
  twice a day, a revised dose, a change that starts in 5 days, an injection in
  units, a syrup course that ends soon, eye drops on three days a week, an
  inhaler, one that starts in a week, a finished course and a stopped one, a
  filled medical file and two emergency contacts;
- a month of dose records: most taken (some late), some skipped with a
  reason, some missed, and today's doses of the last 3 hours left open;
- an invitation she sent 2 days ago to 0559876543 (her sister) to help with
  «دائرة نورة», still waiting;
- an invitation from «سارة» (0500000002) to manage «دائرة عبدالله» in Jeddah;
- a request she sent to 0500000003 (her father) that still waits;
- «دائرة خالد», her uncle's care, which Sara also manages: Khaled is its
  patient and uses the simplified mode. Today he has a dose taken, one late,
  the next one and one later (weekly, monthly and every-other-day
  medicines), a blood pressure and a glucose plan with their targets, a
  reading of his own, and three appointments: one Lina goes to, one only
  Sara goes to (Lina's phone is not reminded of it) and one both go to;
- a blood pressure plan and an appointment in «دائرة نورة».

The day is built around the moment the demo is made, so make it fresh
before showing it.

| What | Command |
|---|---|
| Make it fresh again (today's dates) | `docker compose exec api flask --app wsgi demo-data --reset` |

Everything is made through the app's own services and checked by the
database rules, as if a family had used the app. It only touches the demo
accounts; `--reset` deletes them as the app deletes an account. It refuses to
run in production, and it refuses unless no real SMS can reach the demo
numbers, which are made up: `SMS_BACKEND=fake`, or `DEMO_SIGN_IN_CODE` set.

Sign-in codes: after each code to a number the next one waits 30 s, then 1, 2,
5 and 10 minutes (`OTP_RESEND_WAITS`); a number gets at most 20 codes a day,
counted since its last sign-in (`OTP_MAX_SENDS_PER_DAY`); one device and one
IP get at most 10 and 30 codes an hour (`OTP_MAX_SENDS_PER_DEVICE_HOUR`,
`OTP_MAX_SENDS_PER_IP_HOUR`). Behind a proxy, `CLIENT_IP_HEADER` names the
header with the caller's address (Render: `CF-Connecting-IP`). A phone that
already signed in with a number counts only its own codes, so a stranger who
asks codes for that number cannot lock its owner out.

## Documents

| File | What it holds |
|---|---|
| `docs/api-contracts.md` | The API rules: errors, validation, sign-in tokens, roles, the endpoints that exist (TFQD-11) |
| `docs/authentica-test-guide.md` | How to test the Authentica OTP API and what to record (TFQD-12) |

## What is built, and what is not

- Sign-in with the phone number and the code (F01), the account profile, and the
  home endpoint are built on PostgreSQL. The circle endpoints are built too: create
  a circle, circle requests with consent, invitations, rename, leave, delete, the
  patient's data, the medical file, emergency contacts, the emergency card, and
  account deletion. The
  endpoints and the rules are in `docs/api-contracts.md` (section 5).
- The medical tables (blood type, conditions, allergies, emergency contacts) are a
  design that the team has not approved yet (`docs/api-contracts.md`, section 10).
- Push notifications are built and live, with the team's paid Apple
  Developer account (see "Push notifications").
- Not built: the notifications endpoint, the care plan and the records. The
  emergency card is built without the current medicines (they come with F06).
- This Docker setup is for development. Staging and production are TFQD-10.
- The sign-in endpoints use the sender that `SMS_BACKEND` selects. The Authentica
  sender is tested without a network only (`SMS_BACKEND=authentica` with
  `AUTHENTICA_API_KEY`). `scripts/try_authentica_sender.py` tries it once with the
  real service.

## Push notifications

The server tells a person's phone about a new invitation, a request to care
for them, the answer to their request, a circle that is ready (the same
things as the app's notifications page), and the scheduled scan below (a
dose or measurement due or missed, an appointment the day before). The app
also sets its own dose reminders on the phone itself, independent of the
server's.

Apple sends a push only to an app signed with a **paid** Apple Developer
account that has the Push Notifications capability. The team has one, and
`.env` sets `PUSH_BACKEND=apns`, so this is live. Without it,
`PUSH_BACKEND=none` (the default): the app still sends its phone's token
(`PUT /api/v1/accounts/me/push-device`), but the server sends nothing — the
state a fresh environment (a new developer's machine, a new paid account)
starts in.

To set it up with a paid account:

1. In the Apple Developer website: Certificates, Identifiers & Profiles, then
   Keys, then make a key with **Apple Push Notifications service (APNs)**.
   Download the `.p8` file (Apple gives it only once) and note its Key ID and
   the Team ID (top right of the website).
2. Put the file in `backend/secrets/` (git ignores `*.p8`; never commit it).
3. In your `.env`:
   ```
   PUSH_BACKEND=apns
   APNS_KEY_ID=<the key id>
   APNS_TEAM_ID=<the team id>
   APNS_BUNDLE_ID=<the app's bundle id>
   APNS_PRIVATE_KEY_PATH=/app/secrets/AuthKey_<key id>.p8
   APNS_ENVIRONMENT=sandbox
   ```
   `production` is for TestFlight and the App Store (the way the team installs
   the app); `sandbox` is only for builds signed for development.
4. The app already asks for push (`app/ios/Runner/Runner.entitlements` and
   `RunnerRelease.entitlements`). Build it with `[testflight]` in the commit
   message (`.github/workflows/testflight.yml`, which lists the secrets it
   needs) and install it from TestFlight. The unsigned Sideloadly build
   (`[ios]`) gets no push.
5. `docker compose up -d --force-recreate api`, then open the TestFlight app
   on the phone and sign in.

The code is in `app/push/`. A push that cannot be sent never fails the
request; a token Apple no longer knows is deleted. A signed-out phone gets
nothing, because the token belongs to the sign-in that sent it.

### Scheduled notifications

The reminders before a task are set on each phone by the app itself, so
they come on time with no server and no tick: each dose and measurement at
its time, and each appointment a day before and two hours before
(`app/lib/features/medications/domain/dose_reminders.dart`). The server
only tells what a phone cannot know ahead.

`POST /internal/tick` scans every circle for a dose or measurement whose
time passed with nothing recorded, and sends each exactly once
(`notification_log` records what was already sent, so a repeat call never
resends it). The push goes to every manager of that circle and to its
patient if the patient has an account.

Every push uses the app's own sound, `tafaqod_chime.wav`, the same as the
app's reminders (the app copies it to the phone's `Library/Sounds`; until
the app has run once, iOS plays its default sound).

GitHub runs a scheduled workflow only from the repository's default branch
(`main`), so the tick below starts once `notify-tick.yml` is on `main`.

The route only runs the scan when the `X-Tick-Secret` header equals
`TICK_SECRET`; otherwise it answers 404, the same as a route that does not
exist. Set `TICK_SECRET` in your `.env` (any long random value) and give
the same value to whatever calls it on a schedule.

Something has to call it on a schedule. The repository's own
`.github/workflows/notify-tick.yml` does this for free, every 10 minutes,
using the `TICK_SECRET` repository secret — set that secret once in GitHub
(Settings, Secrets and variables, Actions) and it runs on its own, no
server or paid plan required. On a paid Render plan, a Render Cron Job can
call the same URL and header instead; nothing in the server changes either
way, so switching is just turning one off and the other on.

## Deadlines, breakers and counters

How the server stays up when something it depends on does not.

- **Every call has a deadline.** Authentica 10 seconds, Aladhan 8, Apple 10,
  and the database too: 5 seconds per query, 3 seconds to wait for a lock,
  30 seconds for a transaction left idle, 5 seconds to connect and 5 to get
  a free connection (`DATABASE_*` settings in `.env.example`). A query past
  its deadline answers 503 `database_unavailable`. Migrations lift the query
  deadline for themselves only (`migrations/env.py`).
- **A sick service is not called for a while.** After 3 failed calls in a row
  to Authentica, Aladhan or Apple, that service is not called for 60 seconds
  (`app/resilience.py`): sign-in answers `sms_unavailable` at once (and the
  code is not counted against the number), the home page shows its greeting
  without prayer times, and a push is kept for the next time. There is no
  breaker around our own database.
- **No one waits for a push.** Push notifications are sent after the answer,
  on two background threads (`app/background.py`), so an invitation or the
  scheduled scan never waits for Apple. A push still waiting when the server
  stops is lost; the app shows the same thing when it is opened.
- **Counters to alert on** (`app/metrics.py`), next to the log lines:
  `sign_in.code_sent`, `sign_in.code_not_sent`, `sign_in.code_not_checked`,
  `sign_in.invalid_code`, `sign_in.completed`, `push.sent`, `push.failed`,
  `push.gone`, `prayer_times.unavailable`, `tick.missed_dose`,
  `tick.missed_measurement`, `circuit.<service>.opened` and `.refused`,
  `database.unavailable`, `errors.internal`, `background.failed` and
  `background.dropped`. `GET /internal/metrics` with the `X-Tick-Secret`
  header reads them. Each server process counts on its own from its start
  (Render may run two), so read them as "this is happening now", not as
  totals.

## Deploy to Render

`render.yaml` (at the top of the repository) describes the team's shared test
server on [Render](https://render.com): the API and its PostgreSQL database.
It runs with `APP_ENV=staging` and real SMS codes (Authentica). The
image is the same `Dockerfile`; on Render its start command runs
`flask --app wsgi db upgrade`, then `demo-data --if-missing` (with
`DEMO_DATA=true`), then the production server (gunicorn). Photos and voice
notes are kept in the database, so the API needs no disk.

The first time:

1. Make a Render account. The owner of the GitHub repository connects GitHub
   to Render and gives it this repository.
2. In Render: **New**, then **Blueprint**, pick the repository and the branch
   to deploy.
3. Render asks for the values that are not in git: `PUSH_BACKEND` (`none` for
   now), `APNS_KEY_ID` and `APNS_TEAM_ID`.
4. **Apply**. The first build takes a few minutes. The API's address is at the
   top of its page, such as `https://tfaqud-api.onrender.com`;
   `https://<address>/api/v1/health` answers when it is ready.
5. Push: on the API's page, **Environment**, **Secret Files**, add a file named
   `apns_key.p8` with the text of the `.p8` key. Then set `PUSH_BACKEND` to
   `apns` and **Save and deploy**.
6. Build the app for it: `[testflight api=https://<address>]` in a commit
   message.

Signing in: the code comes by SMS through Authentica (`SMS_BACKEND` is
`authentica`); add `AUTHENTICA_API_KEY` in **Environment** before the first
deploy that uses it, or the server cannot start.

The demo on Render: add `DEMO_SIGN_IN_CODE` (six digits) in **Environment**.
The demo numbers (`0500000001` detailed, `0500000004` simplified) then get no
SMS and sign in with that code; every other number gets its real SMS as
before. The start makes the demo when it is missing (`DEMO_DATA` is
`"true"`), and the workflow **Demo refresh** makes it fresh every morning
and from **Actions**, **Run workflow**, before showing it (it calls
`POST /internal/demo-data` with `TICK_SECRET`). Never set the code in
production: the server refuses to start with it.

For a test server without SMS, set `SMS_BACKEND` to `fake`,
`FAKE_SMS_LOG_CODES` to `"true"` and `DEMO_DATA` to `"true"` in
`render.yaml`: the code is then in the API's **Logs** (search for
`FAKE SMS`), and the demo data is made at the start. The server then runs one
process instead of two: the fake sender keeps its codes in the memory of the
process that sent them, so with two a correct code was refused about every
second try.

After that, every push to the chosen branch deploys again by itself once the
GitHub checks of `.github/workflows/ci.yml` pass on it, with the new
migrations, and the old version answers until the new one is ready. A failed
check deploys nothing.
`[skip render]` in a commit message skips one deploy. Settings change in
**Environment**, without a new commit.

On the free plan the API sleeps after 15 minutes without requests and takes
about a minute to wake, so the first request after a pause can fail once; the
free database is deleted 30 days after it is made unless it is upgraded.

## Flutter in Chrome

A web page cannot call an API on another address unless the API allows it (CORS).
When `APP_ENV` is `development` (the default), the API allows pages served from
`localhost` or `127.0.0.1` and no other website. In `testing`, `staging` and
`production` it allows none. The iPhone app is not a web page and does not need it.
The code is in `app/cors.py`.

## Settings

All settings come from environment variables. `.env.example` lists every one of
them with a comment. The rules are in `app/config.py`.
