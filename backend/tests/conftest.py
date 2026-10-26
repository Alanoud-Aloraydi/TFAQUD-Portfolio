"""Shared test setup.

Every test gets:
  - an app in the "testing" environment (fake SMS only, fixed secret key);
  - a clock that the test can move forward;
  - no network access at all, so no real SMS can leave the machine.
"""

import socket

import pytest

from app import create_app
from app.auth.otp_store import InMemoryOtpStore
from app.authz import InMemoryCircleAccess
from app.clock import ManualClock
from app.users.store import InMemoryUserStore


@pytest.fixture(autouse=True)
def isolate_database_environment(monkeypatch):
    """Unit tests never inherit a developer or container database target."""
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("DATABASE_HOST", raising=False)


@pytest.fixture(autouse=True)
def block_network(monkeypatch):
    """Fail any test that tries to open a network connection."""

    def refuse(*args, **kwargs):
        raise AssertionError("A test tried to open a network connection.")

    monkeypatch.setattr(socket.socket, "connect", refuse)
    monkeypatch.setattr(socket, "create_connection", refuse)


@pytest.fixture
def clock():
    """Start at 2026-10-15 12:00 UTC; advance only when requested by a test."""
    return ManualClock()


@pytest.fixture
def circle_access():
    return InMemoryCircleAccess()


@pytest.fixture
def otp_store():
    """Where the sign-in code requests are kept, so a test can look inside."""
    return InMemoryOtpStore()


@pytest.fixture
def user_store():
    return InMemoryUserStore()


@pytest.fixture
def app(clock, circle_access, otp_store, user_store):
    return create_app(
        "testing",
        clock=clock,
        circle_access=circle_access,
        otp_store=otp_store,
        user_store=user_store,
    )


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def sms(app):
    """The fake SMS sender the app is using."""
    return app.extensions["sms_sender"]


@pytest.fixture
def sessions(app):
    return app.extensions["session_service"]


@pytest.fixture
def signed_in(sessions):
    """A user with a fresh session, as if F01 had just verified their OTP."""
    return sessions.create_session("user-1")


def bearer(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}
