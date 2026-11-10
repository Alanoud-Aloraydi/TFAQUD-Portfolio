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
from app.appointments.routes import bp as appointments_bp
from app.appointments.visit_routes import bp as appointment_visits_bp
from app.auth.routes import bp as auth_bp
from app.auth.service import SessionService
from app.auth.sign_in import SignInService
from app.auth.store import InMemorySessionStore, SessionStore
from app.authz import CircleAccess, DenyAllCircleAccess
from app.circles.creation_requests import bp as creation_requests_bp
from app.circles.invitations import bp as invitations_bp
from app.circles.routes import bp as circles_bp
from app.clock import SystemClock
from app.config import ConfigError, load_config
from app.database import initialize_database, transaction
from app.cors import register_development_cors
from app.demo_routes import bp as demo_bp
from app.errors import register_error_handlers
from app.health import bp as health_bp
from app.home import bp as home_bp
from app.medications.routes import bp as medications_bp
from app.photo_routes import bp as photos_bp
from app.measurements.routes import bp as measurements_bp
from app.prayer_times.routes import bp as prayer_times_bp
from app.push import PushSender, create_push_sender
from app.push.routes import bp as push_bp
from app.push.tick_routes import bp as tick_bp
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
    push_sender: PushSender | None = None,
) -> Flask:
    """Build the Flask app for one environment: read the settings, choose the
    SMS, session, code, user and push services (the PostgreSQL ones when a
    database is set, the in-memory ones otherwise), and register every error
    handler and endpoint. Tests pass their own fakes through the keyword
    arguments.
    """
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
    # Push notifications to signed-in phones; "none" unless set up.
    app.extensions["push_sender"] = push_sender or create_push_sender(
        app.config
    )
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
        max_sends_per_day=app.config["OTP_MAX_SENDS_PER_DAY"],
        resend_waits=app.config["OTP_RESEND_WAITS"],
        max_sends_per_device_hour=app.config["OTP_MAX_SENDS_PER_DEVICE_HOUR"],
        max_sends_per_ip_hour=app.config["OTP_MAX_SENDS_PER_IP_HOUR"],
        transaction=transaction if database_enabled else nullcontext,
    )

    register_request_id(app)
    register_error_handlers(app)
    if env == "development":
        register_development_cors(app)
    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(home_bp)
    app.register_blueprint(circles_bp)
    app.register_blueprint(creation_requests_bp)
    app.register_blueprint(invitations_bp)
    app.register_blueprint(medications_bp)
    app.register_blueprint(photos_bp)
    app.register_blueprint(measurements_bp)
    app.register_blueprint(appointments_bp)
    app.register_blueprint(appointment_visits_bp)
    app.register_blueprint(prayer_times_bp)
    app.register_blueprint(push_bp)
    app.register_blueprint(tick_bp)
    app.register_blueprint(demo_bp)
    if database_enabled and env != "production":
        # `flask --app wsgi demo-data`: demo circles, medicines and doses for
        # trying the app on a local server (app/demo_data.py).
        from app.demo_data import demo_data_command

        app.cli.add_command(demo_data_command)

    return app


def _refuse_in_production(env: str, what: str) -> None:
    """Stop the start-up when production would keep `what` only in memory: it
    would be lost on every restart.
    """
    if env == "production":
        raise ConfigError(
            f"The in-memory {what} store cannot be used in production. "
            f"Connect the PostgreSQL {what} store first."
        )


def _warn_in_staging(app: Flask, env: str, what: str, lost: str) -> None:
    """Warn once at start-up when staging keeps `what` only in memory."""
    if env == "staging":
        app.logger.warning(
            "Using the in-memory %s store: %s are lost on restart "
            "and are not shared between worker processes.",
            what,
            lost,
        )
