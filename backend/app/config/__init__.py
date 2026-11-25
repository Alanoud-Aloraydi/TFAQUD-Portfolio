"""The server's settings: `load_config` reads them from the environment and
refuses settings that are missing or unsafe with `ConfigError`.

Environments: development (local work), testing (fake SMS only, fixed
secret) and production (every secret set, no fakes)."""

import os

from app.config.database import (
    checked_database_uri,
    database_uri,
    engine_options,
)
from app.config.services import service_settings, sign_in_settings
from app.config.values import (
    ConfigError,
    DEV_SECRET_KEY,
    ENVIRONMENTS,
    MIN_SECRET_KEY_LENGTH,
    TEST_SECRET_KEY,
)


def _six_digits(code: str) -> bool:
    return len(code) == 6 and code.isascii() and code.isdigit()


def check_settings(config: dict, env_name: str) -> None:
    """Refuse a bad demo or review code, a database that is not PostgreSQL
    with psycopg 3, and a missing or short secret key. Puts the database
    URL in its checked form."""
    demo_code = config.get("DEMO_SIGN_IN_CODE")
    if demo_code is not None:
        if env_name == "production":
            raise ConfigError("DEMO_SIGN_IN_CODE cannot be set in production.")
        if not _six_digits(demo_code):
            raise ConfigError("DEMO_SIGN_IN_CODE must be six digits.")

    review_code = config.get("REVIEW_SIGN_IN_CODE")
    if bool(review_code) != bool(config.get("REVIEW_SIGN_IN_PHONES")):
        raise ConfigError(
            "REVIEW_SIGN_IN_PHONES and REVIEW_SIGN_IN_CODE go together."
        )
    if review_code is not None and not _six_digits(review_code):
        raise ConfigError("REVIEW_SIGN_IN_CODE must be six digits.")

    uri = config.get("SQLALCHEMY_DATABASE_URI")
    if uri:
        config["SQLALCHEMY_DATABASE_URI"] = checked_database_uri(uri)

    secret = config["SECRET_KEY"]
    if not secret or len(secret) < MIN_SECRET_KEY_LENGTH:
        raise ConfigError(
            f"SECRET_KEY is required in {env_name} and must have at least "
            f"{MIN_SECRET_KEY_LENGTH} characters."
        )


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
        **sign_in_settings(env_name),
        **service_settings(env_name),
        # Unit tests keep explicit fakes; database tests supply their own.
        "SQLALCHEMY_DATABASE_URI": database_uri(env_name),
        "SQLALCHEMY_ENGINE_OPTIONS": engine_options(),
    }
    if env_name == "testing":
        # Tests never read the real environment for secrets or the SMS
        # backend, and hand the app a recording push sender when they
        # need one.
        config["SECRET_KEY"] = TEST_SECRET_KEY
        config["SMS_BACKEND"] = "fake"
        config["AUTHENTICA_API_KEY"] = None
        config["AUTHENTICA_BACKUP_API_KEYS"] = ()
        config["DEMO_SIGN_IN_PHONES"] = ()
        config["REVIEW_SIGN_IN_PHONES"] = ()
        config["REVIEW_SIGN_IN_CODE"] = None
        config["PUSH_BACKEND"] = "none"
    elif env_name == "development" and not config["SECRET_KEY"]:
        config["SECRET_KEY"] = DEV_SECRET_KEY
    if overrides:
        config.update(overrides)
    check_settings(config, env_name)
    return config
