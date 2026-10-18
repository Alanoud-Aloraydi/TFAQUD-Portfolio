"""Shortcuts to the shared services that `create_app` puts on the app.

Views and decorators call these instead of building their own services. This is
what lets tests replace a service (for example the SMS sender) with a fake.
"""

from flask import current_app


def get_clock():
    return current_app.extensions["clock"]


def get_sms_sender():
    return current_app.extensions["sms_sender"]


def get_session_service():
    return current_app.extensions["session_service"]


def get_circle_access():
    return current_app.extensions["circle_access"]
