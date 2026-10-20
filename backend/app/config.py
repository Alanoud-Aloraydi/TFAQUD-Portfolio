"""Application settings.

Settings are read from environment variables when `load_config()` is called, so
tests can change the environment before creating the app.

Environments:
  development - local work. Fake SMS, a built-in secret key.
  testing     - automated tests. Fake SMS only, a fixed secret key.
  staging     - the shared test server (TFQD-10). Needs a real SECRET_KEY.
  production  - the real server. Needs a real SECRET_KEY, refuses the fake SMS
                sender and the in-memory session store.
"""

import os

ENVIRONMENTS = ("development", "testing", "staging", "production")

# Token lifetimes are a proposal (TFQD-11) that the team still has to confirm.
DEFAULT_ACCESS_TOKEN_MINUTES = 15
DEFAULT_REFRESH_TOKEN_DAYS = 30

# The sign-in code (docs/api-contracts.md, section 8). Authentica keeps a code for
# the time set in its dashboard. OTP_VALID_SECONDS must equal that value: the fake
# sender uses it, and the sign-in endpoints use it to choose the message.
DEFAULT_OTP_VALID_SECONDS = 300
DEFAULT_AUTHENTICA_TEMPLATE_ID = 5  # Arabic text, code of 6 digits

# The limits of TFQD-13 / TFQD-35, counted by our server. They are settings, not
# constants, so a test server can relax them without a code change.
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
        raise ConfigError(f"{name} must be a whole number, got {raw!r}.") from exc
    if value <= 0:
        raise ConfigError(f"{name} must be greater than zero, got {value}.")
    return value


def load_config(env_name: str | None = None, overrides: dict | None = None) -> dict:
    """Build the settings dictionary for one environment."""
    env_name = env_name or os.environ.get("APP_ENV", "development")
    if env_name not in ENVIRONMENTS:
        raise ConfigError(
            f"APP_ENV must be one of {', '.join(ENVIRONMENTS)}, got {env_name!r}."
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
        "OTP_VALID_SECONDS": _int_from_env("OTP_VALID_SECONDS", DEFAULT_OTP_VALID_SECONDS),
        "OTP_MAX_WRONG_TRIES": _int_from_env(
            "OTP_MAX_WRONG_TRIES", DEFAULT_OTP_MAX_WRONG_TRIES
        ),
        "OTP_MAX_SENDS_PER_HOUR": _int_from_env(
            "OTP_MAX_SENDS_PER_HOUR", DEFAULT_OTP_MAX_SENDS_PER_HOUR
        ),
        # Needed only when SMS_BACKEND is authentica. Never printed or logged.
        "AUTHENTICA_API_KEY": os.environ.get("AUTHENTICA_API_KEY"),
        "AUTHENTICA_TEMPLATE_ID": _int_from_env(
            "AUTHENTICA_TEMPLATE_ID", DEFAULT_AUTHENTICA_TEMPLATE_ID
        ),
        # In development the developer needs to read the OTP in the log.
        "FAKE_SMS_LOG_BODY": env_name == "development",
    }

    if env_name == "testing":
        # Tests never read the real environment for secrets or the SMS backend.
        config["SECRET_KEY"] = _TEST_SECRET_KEY
        config["SMS_BACKEND"] = "fake"
        config["AUTHENTICA_API_KEY"] = None
    elif env_name == "development" and not config["SECRET_KEY"]:
        config["SECRET_KEY"] = _DEV_SECRET_KEY

    if overrides:
        config.update(overrides)

    secret = config["SECRET_KEY"]
    if not secret or len(secret) < MIN_SECRET_KEY_LENGTH:
        raise ConfigError(
            f"SECRET_KEY is required in {env_name} and must have at least "
            f"{MIN_SECRET_KEY_LENGTH} characters."
        )

    return config
