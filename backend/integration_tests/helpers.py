"""Shared setup and queries for care integration tests."""

from datetime import date, datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.care import CareService

NOW = datetime(2026, 10, 21, 12, tzinfo=timezone.utc)
BIRTH = date(1954, 6, 5)


def run(engine, method, *args, **kwargs):
    """Run a business operation with an independent commit boundary."""
    with Session(engine, expire_on_commit=False) as session:
        with session.begin():
            return getattr(CareService(session, NOW), method)(*args, **kwargs)


def count(engine, model):
    """Count persisted rows using a fresh database snapshot."""
    with Session(engine) as session:
        return session.scalar(select(func.count()).select_from(model))


def offline_circle(engine, owner):
    """Create care for a patient without an application account."""
    return run(
        engine,
        "create_without_account",
        owner.id,
        "Mother Nora",
        "Nora",
        "Family",
        BIRTH,
        "Buraidah",
    )


def add_manager(engine, owner, circle, target):
    """Use the real invitation workflow to add a manager."""
    invitation = run(
        engine, "invite_manager", owner.id, circle.id, target.phone_number
    )
    run(engine, "respond_invitation", target.id, invitation.id, True)
    return invitation


class Api:
    """Call the real endpoints as one signed-in account.

    The session is a real persisted session, issued without sending an SMS,
    like the `signed_in` helper of test_home.py.
    """

    def __init__(self, app, account):
        issued = app.extensions["session_service"].create_session(
            account.id.hex
        )
        self.headers = {"Authorization": "Bearer " + issued.access_token}
        self.client = app.test_client()
        self.account = account

    def call(self, method, url, body=None):
        kwargs = {"headers": self.headers}
        if body is not None:
            kwargs["json"] = body
        return getattr(self.client, method)(url, **kwargs)

    def get(self, url):
        return self.call("get", url)

    def post(self, url, body=None):
        return self.call("post", url, body)

    def put(self, url, body=None):
        return self.call("put", url, body)

    def patch(self, url, body=None):
        return self.call("patch", url, body)

    def delete(self, url, body=None):
        return self.call("delete", url, body)


def error_code(response, status):
    """Check the status and return the stable error code of the answer."""
    assert response.status_code == status, response.get_json()
    return response.get_json()["error"]["code"]
