"""`load_config`: every setting of one environment, checked."""

import os

from app.config.checks import check_settings
from app.config.database import database_uri, engine_options
from app.config.defaults import DEV_SECRET_KEY, ENVIRONMENTS, TEST_SECRET_KEY
from app.config.errors import ConfigError
from app.config.services import service_settings
from app.config.sign_in import sign_in_settings


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
