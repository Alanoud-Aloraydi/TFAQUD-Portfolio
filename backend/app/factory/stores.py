"""The stores of sessions, sign-in codes, users and circle access: the
PostgreSQL ones with a database, the in-memory ones without."""

from dataclasses import dataclass

from flask import Flask

from app.auth.memory_sessions import InMemorySessionStore
from app.auth.otp_store import InMemoryOtpStore, OtpStore
from app.auth.store import SessionStore
from app.authz import CircleAccess, DenyAllCircleAccess
from app.config import ConfigError
from app.users.memory import InMemoryUserStore
from app.users.store import UserStore


@dataclass
class Stores:
    """The stores the services use; given ones (tests' fakes) stay."""

    session: SessionStore | None = None
    otp: OtpStore | None = None
    user: UserStore | None = None
    circle_access: CircleAccess | None = None


def choose_stores(app: Flask, stores: Stores, database: bool) -> Stores:
    """Fill in every store not given."""
    env = app.config["APP_ENV"]
    if stores.session is None:
        if database:
            from app.auth.postgres_sessions import PostgresSessionStore

            stores.session = PostgresSessionStore()
        else:
            _memory_only(app, env, "session", "sessions")
            stores.session = InMemorySessionStore()
    if stores.otp is None:
        if database:
            from app.auth.postgres_otp import PostgresOtpStore

            stores.otp = PostgresOtpStore()
        else:
            _memory_only(
                app, env, "sign-in code", "code requests and their counters"
            )
            stores.otp = InMemoryOtpStore()
    if stores.user is None:
        if database:
            from app.users.postgres import PostgresUserStore

            stores.user = PostgresUserStore()
        else:
            _memory_only(app, env, "user", "users")
            stores.user = InMemoryUserStore()
    if stores.circle_access is None:
        if database:
            from app.authz.postgres import PostgresCircleAccess

            stores.circle_access = PostgresCircleAccess()
        else:
            stores.circle_access = DenyAllCircleAccess()
    return stores


def _memory_only(app: Flask, env: str, what: str, lost: str) -> None:
    """Stop the start-up when production would keep `what` only in memory
    (it would be lost on every restart); warn once when staging does."""
    if env == "production":
        raise ConfigError(
            f"The in-memory {what} store cannot be used in production. "
            f"Connect the PostgreSQL {what} store first."
        )
    if env == "staging":
        app.logger.warning(
            "Using the in-memory %s store: %s are lost on restart "
            "and are not shared between worker processes.",
            what,
            lost,
        )
