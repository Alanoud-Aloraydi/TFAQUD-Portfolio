"""The Flask application factory.

`create_app` is the one place where the pieces are connected (clock, SMS sender,
session store, circle access). Everything else asks for them through
`app.extensions`. Tests call `create_app` with fakes instead of the defaults.
"""

import logging
from datetime import timedelta

from flask import Flask

from app.auth.routes import bp as auth_bp
from app.auth.service import SessionService
from app.auth.store import InMemorySessionStore, SessionStore
from app.authz import CircleAccess, DenyAllCircleAccess
from app.clock import SystemClock
from app.config import ConfigError, load_config
from app.errors import register_error_handlers
from app.health import bp as health_bp
from app.request_context import register_request_id
from app.sms import SmsSender, create_sms_sender


def create_app(
    env_name: str | None = None,
    overrides: dict | None = None,
    *,
    clock=None,
    sms_sender: SmsSender | None = None,
    session_store: SessionStore | None = None,
    circle_access: CircleAccess | None = None,
) -> Flask:
    app = Flask(__name__, static_folder=None)  # an API serves no static files
    app.config.update(load_config(env_name, overrides))
    env = app.config["APP_ENV"]

    if env != "testing":
        # Show INFO messages (such as the fake SMS) on the console. Without
        # this, Python prints only warnings and errors. Tests use pytest's own
        # log capture instead.
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        )

    clock = clock or SystemClock()
    sms_sender = sms_sender or create_sms_sender(app.config, clock)

    if session_store is None:
        if env == "production":
            raise ConfigError(
                "The in-memory session store cannot be used in production. "
                "Connect the PostgreSQL session store first."
            )
        if env == "staging":
            app.logger.warning(
                "Using the in-memory session store: sessions are lost on restart "
                "and are not shared between worker processes."
            )
        session_store = InMemorySessionStore()

    app.extensions["clock"] = clock
    app.extensions["sms_sender"] = sms_sender
    app.extensions["circle_access"] = circle_access or DenyAllCircleAccess()
    app.extensions["session_service"] = SessionService(
        store=session_store,
        secret_key=app.config["SECRET_KEY"],
        access_ttl=timedelta(minutes=app.config["ACCESS_TOKEN_MINUTES"]),
        refresh_ttl=timedelta(days=app.config["REFRESH_TOKEN_DAYS"]),
        clock=clock,
    )

    register_request_id(app)
    register_error_handlers(app)
    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)

    return app
