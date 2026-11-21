"""The checks that keep the server from starting with unsafe settings."""

from app.config.database import checked_database_uri
from app.config.defaults import MIN_SECRET_KEY_LENGTH
from app.config.errors import ConfigError


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
