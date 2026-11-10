"""Shortcuts to the shared services that `create_app` puts on the app.

Views and decorators call these instead of building their own services. This
is what lets tests replace a service (for example the clock) with a fake.
"""

from flask import current_app


def get_clock():
    """The clock of the app: the real one, or the test's."""
    return current_app.extensions["clock"]


def get_session_service():
    """The service that issues, refreshes and revokes sign-in sessions."""
    return current_app.extensions["session_service"]


def get_circle_access():
    """The service that answers which role an account has in a circle."""
    return current_app.extensions["circle_access"]


def get_sign_in_service():
    """The phone sign-in service: sending and checking codes."""
    return current_app.extensions["sign_in_service"]


def get_user_store():
    """Where the accounts are kept."""
    return current_app.extensions["user_store"]


def get_push_sender():
    """The push sender: Apple's, or the one that sends nothing."""
    return current_app.extensions["push_sender"]
