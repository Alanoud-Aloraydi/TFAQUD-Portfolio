"""The Flask application factory.

`create_app` connects the clock, SMS sender, stores, and circle access.
Other modules access these services through `app.extensions`.
Tests call `create_app` with fakes instead of the defaults.
"""

import logging
from contextlib import nullcontext
from datetime import timedelta

from flask import Flask

from app.auth.otp_store import InMemoryOtpStore, OtpStore
from app.auth.routes import bp as auth_bp
from app.auth.service import SessionService
from app.auth.sign_in import SignInService
from app.auth.store import InMemorySessionStore, SessionStore
from app.authz import CircleAccess, DenyAllCircleAccess
from app.clock import SystemClock
from app.config import ConfigError, load_config
from app.database import initialize_database, transaction
from app.cors import register_development_cors
from app.errors import register_error_handlers
from app.health import bp as health_bp
from app.request_context import register_request_id
from app.sms import SmsSender, create_sms_sender
from app.users.routes import bp as users_bp
from app.users.store import InMemoryUserStore, UserStore


def create_app(
    env_name: str | None = None,
    overrides: dict | None = None,
    *,
    clock=None,
    sms_sender: SmsSender | None = None,
    session_store: SessionStore | None = None,
    otp_store: OtpStore | None = None,
    user_store: UserStore | None = None,
    circle_access: CircleAccess | None = None,
) -> Flask:
    app = Flask(__name__, static_folder=None)
    app.config.update(load_config(env_name, overrides))
    env = app.config["APP_ENV"]

    if env != "testing":
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        )

    clock = clock or SystemClock()
    sms_sender = sms_sender or create_sms_sender(app.config, clock)
    database_enabled = initialize_database(app)

    if session_store is None:
        if database_enabled:
            from app.auth.postgres_sessions import PostgresSessionStore

            session_store = PostgresSessionStore()
        else:
            _refuse_in_production(env, "session")
            _warn_in_staging(app, env, "session", "sessions")
            session_store = InMemorySessionStore()
    if otp_store is None:
        if database_enabled:
            from app.auth.postgres_otp import PostgresOtpStore

            otp_store = PostgresOtpStore()
        else:
            _refuse_in_production(env, "sign-in code")
            _warn_in_staging(
                app, env, "sign-in code", "code requests and their counters"
            )
            otp_store = InMemoryOtpStore()
    if user_store is None:
        if database_enabled:
            from app.users.postgres import PostgresUserStore

            user_store = PostgresUserStore()
        else:
            _refuse_in_production(env, "user")
            _warn_in_staging(app, env, "user", "users")
            user_store = InMemoryUserStore()

    if circle_access is None and database_enabled:
        from app.authz.postgres import PostgresCircleAccess

        circle_access = PostgresCircleAccess()

    app.extensions["clock"] = clock
    app.extensions["sms_sender"] = sms_sender
    app.extensions["circle_access"] = circle_access or DenyAllCircleAccess()
    session_service = SessionService(
        store=session_store,
        secret_key=app.config["SECRET_KEY"],
        access_ttl=timedelta(minutes=app.config["ACCESS_TOKEN_MINUTES"]),
        refresh_ttl=timedelta(days=app.config["REFRESH_TOKEN_DAYS"]),
        clock=clock,
    )
    app.extensions["session_service"] = session_service
    app.extensions["user_store"] = user_store
    app.extensions["sign_in_service"] = SignInService(
        otp_store=otp_store,
        user_store=user_store,
        sms_sender=sms_sender,
        session_service=session_service,
        clock=clock,
        otp_valid_seconds=app.config["OTP_VALID_SECONDS"],
        max_wrong_tries=app.config["OTP_MAX_WRONG_TRIES"],
        max_sends_per_hour=app.config["OTP_MAX_SENDS_PER_HOUR"],
        transaction=transaction if database_enabled else nullcontext,
    )

    register_request_id(app)
    register_error_handlers(app)
    if env == "development":
        register_development_cors(app)
    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(users_bp)

    return app


def _refuse_in_production(env: str, what: str) -> None:
    if env == "production":
        raise ConfigError(
            f"The in-memory {what} store cannot be used in production. "
            f"Connect the PostgreSQL {what} store first."
        )


def _warn_in_staging(app: Flask, env: str, what: str, lost: str) -> None:
    if env == "staging":
        app.logger.warning(
            "Using the in-memory %s store: %s are lost on restart "
            "and are not shared between worker processes.",
            what,
            lost,
        )
