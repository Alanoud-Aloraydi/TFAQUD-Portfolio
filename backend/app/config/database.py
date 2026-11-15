"""The database settings: where it is, and the deadlines of every
connection."""

import os

from sqlalchemy.engine import URL, make_url
from sqlalchemy.exc import ArgumentError

from app.config.defaults import (
    DEFAULT_DATABASE_CONNECT_TIMEOUT_SECONDS,
    DEFAULT_DATABASE_IDLE_IN_TRANSACTION_MS,
    DEFAULT_DATABASE_LOCK_TIMEOUT_MS,
    DEFAULT_DATABASE_POOL_TIMEOUT_SECONDS,
    DEFAULT_DATABASE_STATEMENT_TIMEOUT_MS,
)
from app.config.env_values import int_from_env
from app.config.errors import ConfigError


def engine_options() -> dict:
    """The pool and the deadlines of every database connection."""
    statement = int_from_env(
        "DATABASE_STATEMENT_TIMEOUT_MS", DEFAULT_DATABASE_STATEMENT_TIMEOUT_MS
    )
    lock = int_from_env(
        "DATABASE_LOCK_TIMEOUT_MS", DEFAULT_DATABASE_LOCK_TIMEOUT_MS
    )
    idle = int_from_env(
        "DATABASE_IDLE_IN_TRANSACTION_MS",
        DEFAULT_DATABASE_IDLE_IN_TRANSACTION_MS,
    )
    return {
        "pool_pre_ping": True,
        "isolation_level": "READ COMMITTED",
        "hide_parameters": True,
        "pool_timeout": int_from_env(
            "DATABASE_POOL_TIMEOUT_SECONDS",
            DEFAULT_DATABASE_POOL_TIMEOUT_SECONDS,
        ),
        "connect_args": {
            "connect_timeout": int_from_env(
                "DATABASE_CONNECT_TIMEOUT_SECONDS",
                DEFAULT_DATABASE_CONNECT_TIMEOUT_SECONDS,
            ),
            # Set when the connection opens, so they hold for every query;
            # migrations lift the statement one (migrations/env.py).
            "options": (
                f"-c statement_timeout={statement} "
                f"-c lock_timeout={lock} "
                f"-c idle_in_transaction_session_timeout={idle}"
            ),
        },
    }


def database_uri(env_name: str):
    """DATABASE_URL, else one made of DATABASE_HOST and the POSTGRES_*
    settings; None in tests, which supply their own."""
    if env_name == "testing":
        return None
    uri = os.environ.get("DATABASE_URL")
    if not uri and os.environ.get("DATABASE_HOST"):
        uri = URL.create(
            "postgresql+psycopg",
            username=os.environ.get("POSTGRES_USER", "tfaqud"),
            password=os.environ.get("POSTGRES_PASSWORD"),
            host=os.environ["DATABASE_HOST"],
            port=int_from_env("DATABASE_PORT", 5432),
            database=os.environ.get("POSTGRES_DB", "tfaqud"),
        )
    return uri


def checked_database_uri(uri):
    """`uri` as a PostgreSQL URL with the psycopg 3 driver; refused when it
    is anything else."""
    try:
        url = make_url(uri)
    except (ArgumentError, TypeError):
        raise ConfigError("Invalid database connection settings.") from None
    if url.get_backend_name() != "postgresql":
        raise ConfigError("The care schema requires PostgreSQL.")
    if url.drivername == "postgresql":
        url = url.set(drivername="postgresql+psycopg")
    if url.drivername != "postgresql+psycopg":
        raise ConfigError("The database driver must be psycopg 3.")
    return url
