"""The Flask application factory.

`create_app` connects the clock, SMS sender, stores, and circle access.
Other modules access these services through `app.extensions`.
Tests call `create_app` with fakes instead of the defaults.
"""

import logging

from flask import Flask

from app.auth.otp_store import OtpStore
from app.auth.sessions import SessionStore
from app.authz import CircleAccess
from app.clock import SystemClock
from app.config import load_config
from app.database import initialize_database
from app.factory import register_commands, register_endpoints
from app.factory import register_services
from app.background import install_minute_scan
from app.factory import Stores, choose_stores
from app.push import PushSender, create_push_sender
from app.sms import SmsSender, create_sms_sender
from app.users.store import UserStore


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
    if app.config["APP_ENV"] != "testing":
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        )
    clock = clock or SystemClock()
    sms_sender = sms_sender or create_sms_sender(app.config, clock)
    database = initialize_database(app)
    stores = choose_stores(
        app,
        Stores(session_store, otp_store, user_store, circle_access),
        database,
    )
    register_services(
        app,
        stores,
        clock=clock,
        sms_sender=sms_sender,
        push_sender=push_sender or create_push_sender(app.config),
        database=database,
    )
    register_endpoints(app)
    register_commands(app, database)
    install_minute_scan(app, database)
    return app
