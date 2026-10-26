"""Application settings.

Settings are read from environment variables when `load_config()` is called, so
tests can change the environment before creating the app.

Environments:
  development - local work. Configurable SMS, a default development secret.
  testing     - automated tests. Fake SMS only, a fixed secret key.
  staging     - the shared test server (TFQD-10). Needs a real SECRET_KEY.
  production  - the real server. Needs a real SECRET_KEY, refuses the fake SMS
                sender and the in-memory session store.
"""

import os

from sqlalchemy.engine import URL, make_url
from sqlalchemy.exc import ArgumentError

ENVIRONMENTS = ("development", "testing", "staging", "production")

# Default token lifetimes, overridable through environment variables.
DEFAULT_ACCESS_TOKEN_MINUTES = 15
DEFAULT_REFRESH_TOKEN_DAYS = 30

# OTP validity matches the provider's configured lifetime.
DEFAULT_OTP_VALID_SECONDS = 300
DEFAULT_AUTHENTICA_TEMPLATE_ID = 5  # Arabic text, code of 6 digits

# Server-side limits are configurable per environment.
DEFAULT_OTP_MAX_WRONG_TRIES = 3  # per verification request
DEFAULT_OTP_MAX_SENDS_PER_HOUR = 3  # per phone number

MIN_SECRET_KEY_LENGTH = 32

_DEV_SECRET_KEY = "development-only-secret-key-not-for-real-use"
_TEST_SECRET_KEY = "testing-only-secret-key-not-for-real-use!!"


class ConfigError(RuntimeError):
    """The settings are missing or unsafe. The app must not start."""


def _int_from_env(name: str, default: int) -> int:
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    try:
        value = int(raw)
    except ValueError as exc:
        raise ConfigError(
            f"{name} must be a whole number, got {raw!r}."
        ) from exc
    if value <= 0:
        raise ConfigError(f"{name} must be greater than zero, got {value}.")
    return value


def load_config(
    env_name: str | None = None, overrides: dict | None = None
) -> dict:
    """Build the settings dictionary for one environment."""
    env_name = env_name or os.environ.get("APP_ENV", "development")
    if env_name not in ENVIRONMENTS:
        raise ConfigError(
            f"APP_ENV must be one of {', '.join(ENVIRONMENTS)}, "
            f"got {env_name!r}."
        )

    config = {
        "APP_ENV": env_name,
        "TESTING": env_name == "testing",
        "SECRET_KEY": os.environ.get("SECRET_KEY"),
        "ACCESS_TOKEN_MINUTES": _int_from_env(
            "ACCESS_TOKEN_MINUTES", DEFAULT_ACCESS_TOKEN_MINUTES
        ),
        "REFRESH_TOKEN_DAYS": _int_from_env(
            "REFRESH_TOKEN_DAYS", DEFAULT_REFRESH_TOKEN_DAYS
        ),
        "SMS_BACKEND": os.environ.get("SMS_BACKEND", "fake"),
        "OTP_VALID_SECONDS": _int_from_env(
            "OTP_VALID_SECONDS", DEFAULT_OTP_VALID_SECONDS
        ),
        "OTP_MAX_WRONG_TRIES": _int_from_env(
            "OTP_MAX_WRONG_TRIES", DEFAULT_OTP_MAX_WRONG_TRIES
        ),
        "OTP_MAX_SENDS_PER_HOUR": _int_from_env(
            "OTP_MAX_SENDS_PER_HOUR", DEFAULT_OTP_MAX_SENDS_PER_HOUR
        ),
        # Provider credentials remain server-side.
        "AUTHENTICA_API_KEY": os.environ.get("AUTHENTICA_API_KEY"),
        "AUTHENTICA_TEMPLATE_ID": _int_from_env(
            "AUTHENTICA_TEMPLATE_ID", DEFAULT_AUTHENTICA_TEMPLATE_ID
        ),
        # Only the fake sender uses development OTP logging.
        "FAKE_SMS_LOG_BODY": env_name == "development",
        "SQLALCHEMY_DATABASE_URI": None,
        "SQLALCHEMY_ENGINE_OPTIONS": {
            "pool_pre_ping": True,
            "isolation_level": "READ COMMITTED",
            "hide_parameters": True,
        },
    }

    # Unit tests keep explicit fakes; database tests supply their own URL.
    if env_name != "testing":
        config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
        if not config["SQLALCHEMY_DATABASE_URI"] and os.environ.get(
            "DATABASE_HOST"
        ):
            config["SQLALCHEMY_DATABASE_URI"] = URL.create(
                "postgresql+psycopg",
                username=os.environ.get("POSTGRES_USER", "tfaqud"),
                password=os.environ.get("POSTGRES_PASSWORD"),
                host=os.environ["DATABASE_HOST"],
                port=_int_from_env("DATABASE_PORT", 5432),
                database=os.environ.get("POSTGRES_DB", "tfaqud"),
            )

    if env_name == "testing":
        # Tests never read the real environment for secrets or the SMS backend.
        config["SECRET_KEY"] = _TEST_SECRET_KEY
        config["SMS_BACKEND"] = "fake"
        config["AUTHENTICA_API_KEY"] = None
    elif env_name == "development" and not config["SECRET_KEY"]:
        config["SECRET_KEY"] = _DEV_SECRET_KEY

    if overrides:
        config.update(overrides)

    uri = config.get("SQLALCHEMY_DATABASE_URI")
    if uri:
        try:
            url = make_url(uri)
        except (ArgumentError, TypeError):
            raise ConfigError(
                "Invalid database connection settings."
            ) from None
        if url.get_backend_name() != "postgresql":
            raise ConfigError("The care schema requires PostgreSQL.")
        if url.drivername == "postgresql":
            url = url.set(drivername="postgresql+psycopg")
        if url.drivername != "postgresql+psycopg":
            raise ConfigError("The database driver must be psycopg 3.")
        config["SQLALCHEMY_DATABASE_URI"] = url

    secret = config["SECRET_KEY"]
    if not secret or len(secret) < MIN_SECRET_KEY_LENGTH:
        raise ConfigError(
            f"SECRET_KEY is required in {env_name} and must have at least "
            f"{MIN_SECRET_KEY_LENGTH} characters."
        )

    return config
