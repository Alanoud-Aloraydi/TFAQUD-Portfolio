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

Editing a file in `app/` reloads the server by itself.

### If something fails

| Message | Cause and fix |
|---|---|
| `unknown flag: --build`, or `'compose' is not a docker command` | The Compose plugin is missing, or Docker is not connected to your terminal. On Windows with WSL: open Docker Desktop, go to Settings, Resources, WSL Integration, enable your Linux distribution, press Apply, then open a new WSL terminal. On Linux: install the `docker-compose-plugin` package from Docker's apt repository. Then check again with `docker compose version`. |
| `env file .env not found` | Do step 1. |
| `Set POSTGRES_PASSWORD in the .env file` | Do step 2. |
| `The "..." variable is not set. Defaulting to a blank string` | A value in `.env` contains a `$`. Compose treats the text after it as a variable name. Change the value to letters and digits only. A `$` in the middle of a value silently cuts the value at that point. |
| `port is already allocated` or `address already in use` (port 5000) | On macOS, AirPlay Receiver uses port 5000. In `.env`, remove the `#` from `API_PORT=5000` and set another number, for example `5001`. Then use that number in the `curl` command. |
| `ports are not available` or `port is already allocated` (port 5432) | A PostgreSQL is already running on your computer. In `.env`, remove the `#` from `DB_PORT=5432` and set another number, for example `5433`. Then run `docker compose up` again. |

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

## Documents

| File | What it holds |
|---|---|
| `docs/api-contracts.md` | The API rules: errors, validation, sign-in tokens, roles, the endpoints that exist (TFQD-11) |
| `docs/authentica-test-guide.md` | How to test the Authentica OTP API and what to record (TFQD-12) |

## What is not here yet

- The API does not connect to the PostgreSQL container yet. The database
  connection and the tables come with TFQD-7.
- Sessions, users and sign-in code requests are kept in memory until then. They are
  lost when the server restarts.
- This Docker setup is for development. Staging and production are TFQD-10.
- Sign-in with the phone number and the code (F01) is built: `request-code`,
  `verify-code` and the profile endpoint. They run on the in-memory stores above, and
  the Flutter app is not connected to them yet. The endpoints and the rules are in
  `docs/api-contracts.md` (section 5).
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
