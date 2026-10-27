"""Helpers shared by the circle, request and invitation endpoints."""

from contextlib import contextmanager
from datetime import datetime
from functools import cached_property
from uuid import UUID

from flask import current_app, jsonify
from sqlalchemy.orm import Session

from app.auth.decorators import current_auth
from app.care import CareService
from app.database import transaction
from app.errors import Forbidden, NotFound, ServiceUnavailable
from app.extensions import get_clock
from app.medical import MedicalService


class Work:
    """What one request needs: its transaction, the time, and who is asking."""

    def __init__(self, session: Session, now: datetime, actor: UUID):
        self.session = session
        self.now = now
        self.actor = actor
        self.care = CareService(session, now)

    @cached_property
    def medical(self) -> MedicalService:
        return MedicalService(self.session, self.now)


@contextmanager
def care_work(*, hide_forbidden: str | None = None):
    """Run one request's database work in one transaction.

    The transaction commits when the block ends, and the circle rules that
    are checked at commit are checked then. Build the answer inside the
    block, from plain values, and return it after the block.

    For an endpoint that takes the id of a request or an invitation (not a
    circle), pass `hide_forbidden` with the "not found" message. Then an id
    that belongs to someone else looks the same as an id that does not exist,
    and nobody can probe ids.
    """
    if "sqlalchemy" not in current_app.extensions:
        raise ServiceUnavailable()
    actor = UUID(current_auth().user_id)
    with transaction() as session:
        try:
            yield Work(session, get_clock().now(), actor)
        except Forbidden as exc:
            if hide_forbidden is None:
                raise
            raise NotFound(hide_forbidden) from exc


def answer(body: dict, status: int = 200):
    """Circle data is private and changes often, so it is never cached."""
    response = jsonify(body)
    response.status_code = status
    response.headers["Cache-Control"] = "no-store"
    return response


def save_medical(work: Work, circle_id: UUID, profile) -> None:
    """Save the optional medical part of a creation request, same commit."""
    if profile is not None:
        work.medical.update_profile(work.actor, circle_id, profile.to_update())


def parse_id(value: str, what: str) -> UUID:
    """An id from the URL. A value that is not an id is simply not found."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise NotFound(f"The {what} does not exist.") from None
