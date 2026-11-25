"""The parts `create_app` puts together: the stores (PostgreSQL with a
database, in memory without), the services every request reaches through
`app.extensions`, every endpoint with the request id, error handlers and
development CORS around them, and the commands."""

import re
import uuid
from contextlib import nullcontext
from dataclasses import dataclass
from datetime import timedelta

from flask import Flask, g, request

from app.appointments.routes import bp as appointments_bp
from app.appointments.visit_routes import bp as appointment_visits_bp
from app.auth.otp_memory import InMemoryOtpStore
from app.auth.otp_store import OtpStore
from app.auth.routes import bp as auth_bp
from app.auth.service import SessionService
from app.auth.sessions import InMemorySessionStore, SessionStore
from app.auth.sign_in import SignInService
from app.authz import CircleAccess, DenyAllCircleAccess
from app.circles.request_routes import bp as creation_requests_bp
from app.circles.invitations import invitations_bp
from app.circles.medical_routes import bp as circle_medical_bp
from app.circles.member_routes import bp as circle_members_bp
from app.circles.previous import previous_bp as previous_notifications_bp
from app.circles.routes import bp as circles_bp
from app.config.values import ConfigError
from app.database import transaction
from app.demo import bp as demo_bp
from app.error_handlers import register_error_handlers
from app.health import bp as health_bp
from app.home import bp as home_bp
from app.legal.routes import bp as legal_bp
from app.measurements.reading_routes import bp as measurement_readings_bp
from app.measurements.routes import bp as measurements_bp
from app.medications.dose_routes import bp as medication_doses_bp
from app.medications.routes import bp as medications_bp
from app.photos.circle_routes import bp as circle_photos_bp
from app.photos.routes import bp as photos_bp
from app.prayer_times import bp as prayer_times_bp
from app.push.routes import bp as push_bp
from app.push.routes import tick_bp
from app.snoozes.routes import bp as snoozes_bp
from app.users.routes import bp as users_bp
from app.users.store import InMemoryUserStore, UserStore


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
            from app.auth.sessions import PostgresSessionStore

            stores.session = PostgresSessionStore()
        else:
            _memory_only(app, env, "session", "sessions")
            stores.session = InMemorySessionStore()
    if stores.otp is None:
        if database:
            from app.auth.otp_postgres import PostgresOtpStore

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
            from app.authz import PostgresCircleAccess

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


def register_services(
    app: Flask, stores: Stores, *, clock, sms_sender, push_sender,
    database: bool,
) -> None:
    """Make the session and sign-in services and keep every service in
    `app.extensions`."""
    config = app.config
    session_service = SessionService(
        store=stores.session,
        secret_key=config["SECRET_KEY"],
        access_ttl=timedelta(minutes=config["ACCESS_TOKEN_MINUTES"]),
        clock=clock,
    )
    app.extensions.update({
        "clock": clock,
        "sms_sender": sms_sender,
        # Push notifications to signed-in phones; "none" unless set up.
        "push_sender": push_sender,
        "circle_access": stores.circle_access,
        "session_service": session_service,
        "user_store": stores.user,
        "sign_in_service": SignInService(
            otp_store=stores.otp,
            user_store=stores.user,
            sms_sender=sms_sender,
            session_service=session_service,
            clock=clock,
            otp_valid_seconds=config["OTP_VALID_SECONDS"],
            max_wrong_tries=config["OTP_MAX_WRONG_TRIES"],
            max_sends_per_day=config["OTP_MAX_SENDS_PER_DAY"],
            resend_waits=config["OTP_RESEND_WAITS"],
            max_sends_per_device_hour=config[
                "OTP_MAX_SENDS_PER_DEVICE_HOUR"
            ],
            max_sends_per_ip_hour=config["OTP_MAX_SENDS_PER_IP_HOUR"],
            transaction=transaction if database else nullcontext,
        ),
    })


_SAFE_REQUEST_ID = re.compile(r"[A-Za-z0-9_-]{1,64}")


def register_request_id(app: Flask) -> None:
    """Give every request an id, the one the app sent when it is safe, so a log
    line and an error answer can be matched.
    """
    @app.before_request
    def assign_request_id():
        """Keep the app's X-Request-ID when it is a short safe value; make a
        new one otherwise.
        """
        supplied = request.headers.get("X-Request-ID", "")
        # fullmatch: the whole value must fit the pattern. (`$` would also
        # accept a value that ends with a newline.)
        g.request_id = (
            supplied
            if _SAFE_REQUEST_ID.fullmatch(supplied)
            else uuid.uuid4().hex
        )

    @app.after_request
    def return_request_id(response):
        """Send the request's id back in the X-Request-ID header."""
        response.headers["X-Request-ID"] = g.get("request_id", "")
        return response


# http or https, then localhost or 127.0.0.1, then an optional port.
_LOCAL_ORIGIN = re.compile(
    r"^https?://(localhost|127\.0\.0\.1)(:[0-9]{1,5})?$"
)

_ALLOWED_HEADERS = "Authorization, Content-Type, X-Request-ID"

_ALLOWED_METHODS = "GET, POST, PUT, PATCH, DELETE, OPTIONS"

# Headers the page may read from an answer (a browser hides all others).
_EXPOSED_HEADERS = "X-Request-ID, Retry-After"

_PREFLIGHT_CACHE_SECONDS = "600"


def register_development_cors(app: Flask) -> None:
    """In development only, let a page served from this computer (Flutter in
    Chrome) call the API.
    """
    @app.after_request
    def add_cors_headers(response):
        """Add the CORS headers to an answer to a local page, and nothing for
        any other origin.
        """
        origin = request.headers.get("Origin", "")
        # The answer depends on the Origin header, so caches must know it.
        response.vary.add("Origin")
        if _LOCAL_ORIGIN.fullmatch(origin):
            headers = response.headers
            headers["Access-Control-Allow-Origin"] = origin
            headers["Access-Control-Allow-Headers"] = _ALLOWED_HEADERS
            headers["Access-Control-Allow-Methods"] = _ALLOWED_METHODS
            headers["Access-Control-Expose-Headers"] = _EXPOSED_HEADERS
            headers["Access-Control-Max-Age"] = _PREFLIGHT_CACHE_SECONDS
        return response


BLUEPRINTS = (
    health_bp, auth_bp, users_bp, home_bp, circles_bp, circle_members_bp,
    circle_medical_bp, creation_requests_bp, invitations_bp,
    previous_notifications_bp, medications_bp, medication_doses_bp,
    photos_bp, circle_photos_bp, measurements_bp, measurement_readings_bp,
    appointments_bp, appointment_visits_bp,
    prayer_times_bp, push_bp, tick_bp, snoozes_bp, demo_bp, legal_bp,
)


def register_endpoints(app: Flask) -> None:
    """Register the request id, the error handlers, CORS in development and
    every blueprint."""
    register_request_id(app)
    register_error_handlers(app)
    if app.config["APP_ENV"] == "development":
        register_development_cors(app)
    for blueprint in BLUEPRINTS:
        app.register_blueprint(blueprint)


def register_commands(app: Flask, database: bool) -> None:
    """The `flask --app wsgi` commands that need the database."""
    if not database:
        return
    # `tick`: the scheduled notification scan, which Render's cron job runs
    # every 10 minutes (render.yaml).
    from app.push.routes import tick_command

    app.cli.add_command(tick_command)
    if app.config["APP_ENV"] != "production":
        # `demo-data`: demo circles, medicines and doses for trying the app
        # on a local server (app/demo_data/).
        from app.demo_data import demo_data_command

        app.cli.add_command(demo_data_command)
        # `keep-only`: only some accounts stay, on a test server
        # (app/keep_only/).
        from app.keep_only import keep_only_command

        app.cli.add_command(keep_only_command)
