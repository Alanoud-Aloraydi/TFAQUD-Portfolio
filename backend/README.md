# Back end

The Flask REST API (base path `/v1`) and its PostgreSQL database.

## Run

```bash
cp .env.example .env
docker compose up
```

The API starts on the port set in `.env`. Check it with `GET /v1/health`, which returns `200 {status}`.

The Docker files and `.env.example` are added by KAN-12.

## Test

```bash
pytest
```

The tests use the Flask test client and a PostgreSQL test database.

## Notes

- Settings (database address, secret keys, provider keys) are read from environment variables. Never commit `.env`.
- Every new endpoint verifies the caller's role and has a test for the refusal.