"""Application settings.

Settings are read from environment variables when `load_config()` is called, so
tests can change the environment before creating the app.

Environments:
  development - local work. Configurable SMS, a default development secret.
  testing     - automated tests. Fake SMS only, a fixed secret key.
  staging     - the shared test server (TFQD-10, Render). Needs a real
                SECRET_KEY; logs the fake sender's codes when
                FAKE_SMS_LOG_CODES=true.
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
# Codes to one phone number in 24 hours, counted since its last sign-in.
DEFAULT_OTP_MAX_SENDS_PER_DAY = 20
# Seconds to wait after the 1st, 2nd, 3rd ... code before the next one; the
# last one repeats. Someone who types another person's number can then only
# slow the owner (at most 10 minutes), never lock them out.
DEFAULT_OTP_RESEND_WAITS = (30, 60, 120, 300, 600)
# Codes one device (X-Device-Id) and one IP may ask for in an hour, for any
# numbers, so one phone or one network cannot send codes to many people.
DEFAULT_OTP_MAX_SENDS_PER_DEVICE_HOUR = 10
DEFAULT_OTP_MAX_SENDS_PER_IP_HOUR = 30

MIN_SECRET_KEY_LENGTH = 32

_DEV_SECRET_KEY = "development-only-secret-key-not-for-real-use"
_TEST_SECRET_KEY = "testing-only-secret-key-not-for-real-use!!"


class ConfigError(RuntimeError):
    """The settings are missing or unsafe. The app must not start."""


def _waits_from_env(name: str, default: tuple[int, ...]) -> tuple[int, ...]:
    """Whole seconds separated by commas, such as "30,60,120"; "0": none."""
    raw = os.environ.get(name)
    if raw is None or raw.strip() == "":
        return default
    if raw.strip() == "0":
        return ()
    try:
        waits = tuple(int(part) for part in raw.split(","))
    except ValueError as exc:
        raise ConfigError(
            f"{name} must be whole seconds separated by commas, got {raw!r}."
        ) from exc
    if any(wait <= 0 for wait in waits):
        raise ConfigError(f"{name} must hold numbers greater than zero.")
    return waits


def _cap_from_env(name: str, default: int | None) -> int | None:
    """A whole number greater than zero, or "0" for no cap."""
    raw = os.environ.get(name)
    if raw is not None and raw.strip() == "0":
        return None
    if raw is None or raw == "":
        return default
    return _int_from_env(name, 1)


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
        "OTP_MAX_SENDS_PER_DAY": _int_from_env(
            "OTP_MAX_SENDS_PER_DAY", DEFAULT_OTP_MAX_SENDS_PER_DAY
        ),
        # The tests send many codes in a row: there, no waits and no device
        # or IP caps unless a test sets them.
        "OTP_RESEND_WAITS": _waits_from_env(
            "OTP_RESEND_WAITS",
            () if env_name == "testing" else DEFAULT_OTP_RESEND_WAITS,
        ),
        "OTP_MAX_SENDS_PER_DEVICE_HOUR": _cap_from_env(
            "OTP_MAX_SENDS_PER_DEVICE_HOUR",
            None
            if env_name == "testing"
            else DEFAULT_OTP_MAX_SENDS_PER_DEVICE_HOUR,
        ),
        "OTP_MAX_SENDS_PER_IP_HOUR": _cap_from_env(
            "OTP_MAX_SENDS_PER_IP_HOUR",
            None
            if env_name == "testing"
            else DEFAULT_OTP_MAX_SENDS_PER_IP_HOUR,
        ),
        # The header that holds the caller's real address behind a proxy
        # (Render: CF-Connecting-IP). Empty: the connection's address.
        "CLIENT_IP_HEADER": os.environ.get("CLIENT_IP_HEADER", "").strip(),
        # Provider credentials remain server-side.
        "AUTHENTICA_API_KEY": os.environ.get("AUTHENTICA_API_KEY"),
        "AUTHENTICA_TEMPLATE_ID": _int_from_env(
            "AUTHENTICA_TEMPLATE_ID", DEFAULT_AUTHENTICA_TEMPLATE_ID
        ),
        # Only the fake sender logs its codes: always in development, and in
        # staging when FAKE_SMS_LOG_CODES=true (a shared test server whose log
        # only the team can read, such as Render). Never in production, which
        # refuses the fake sender anyway.
        "FAKE_SMS_LOG_BODY": env_name == "development"
        or (
            env_name == "staging"
            and os.environ.get("FAKE_SMS_LOG_CODES", "").strip().lower()
            in ("1", "true", "yes")
        ),
        # Push notifications: "none" (nothing is sent) or "apns" (Apple,
        # needs a paid Apple Developer account and its .p8 key).
        "PUSH_BACKEND": os.environ.get("PUSH_BACKEND", "none"),
        "APNS_KEY_ID": os.environ.get("APNS_KEY_ID"),
        "APNS_TEAM_ID": os.environ.get("APNS_TEAM_ID"),
        "APNS_BUNDLE_ID": os.environ.get("APNS_BUNDLE_ID"),
        "APNS_PRIVATE_KEY_PATH": os.environ.get("APNS_PRIVATE_KEY_PATH"),
        "APNS_ENVIRONMENT": os.environ.get("APNS_ENVIRONMENT", "sandbox"),
        # The one code the demo accounts (app/demo_accounts.py) sign in
        # with, six digits, so a shared test server with real SMS can show
        # the demo: those made-up numbers get no SMS. Unset: no demo
        # sign-in. Refused in production.
        "DEMO_SIGN_IN_CODE": (
            os.environ.get("DEMO_SIGN_IN_CODE", "").strip() or None
        ),
        # Shared secret for the external scheduler's call to /internal/tick.
        # None (unset) keeps the endpoint refusing every request.
        "TICK_SECRET": os.environ.get("TICK_SECRET"),
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
        # Tests hand the app a recording sender when they need one.
        config["PUSH_BACKEND"] = "none"
    elif env_name == "development" and not config["SECRET_KEY"]:
        config["SECRET_KEY"] = _DEV_SECRET_KEY

    if overrides:
        config.update(overrides)

    demo_code = config.get("DEMO_SIGN_IN_CODE")
    if demo_code is not None:
        if env_name == "production":
            raise ConfigError("DEMO_SIGN_IN_CODE cannot be set in production.")
        if not (len(demo_code) == 6 and demo_code.isascii()
                and demo_code.isdigit()):
            raise ConfigError("DEMO_SIGN_IN_CODE must be six digits.")

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
