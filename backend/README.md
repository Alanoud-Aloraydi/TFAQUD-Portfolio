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

## Settings

All settings come from environment variables. `.env.example` lists every one of
them with a comment. The rules are in `app/config.py`.
