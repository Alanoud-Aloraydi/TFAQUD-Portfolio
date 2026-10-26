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

The tables are created by migrations (`migrations/versions/0001` to `0005`),
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

## Documents

| File | What it holds |
|---|---|
| `docs/api-contracts.md` | The API rules: errors, validation, sign-in tokens, roles, the endpoints that exist (TFQD-11) |
| `docs/authentica-test-guide.md` | How to test the Authentica OTP API and what to record (TFQD-12) |

## What is built, and what is not

- Sign-in with the phone number and the code (F01), the account profile, and the
  home endpoint are built on PostgreSQL. The circle endpoints are built too: create
  a circle, circle requests with consent, invitations, rename, leave, delete, the
  patient's data, the medical file, emergency contacts, and account deletion. The
  endpoints and the rules are in `docs/api-contracts.md` (section 5).
- The medical tables (blood type, conditions, allergies, emergency contacts) are a
  design that the team has not approved yet (`docs/api-contracts.md`, section 10).
- Not built: the notifications endpoint, the emergency card, the care plan and the
  records.
- This Docker setup is for development. Staging and production are TFQD-10.
- The sign-in endpoints use the sender that `SMS_BACKEND` selects. The Authentica
  sender is tested without a network only (`SMS_BACKEND=authentica` with
  `AUTHENTICA_API_KEY`). `scripts/try_authentica_sender.py` tries it once with the
  real service.

## Flutter in Chrome

A web page cannot call an API on another address unless the API allows it (CORS).
When `APP_ENV` is `development` (the default), the API allows pages served from
`localhost` or `127.0.0.1` and no other website. In `testing`, `staging` and
`production` it allows none. The iPhone app is not a web page and does not need it.
The code is in `app/cors.py`.

## Settings

All settings come from environment variables. `.env.example` lists every one of
them with a comment. The rules are in `app/config.py`.
