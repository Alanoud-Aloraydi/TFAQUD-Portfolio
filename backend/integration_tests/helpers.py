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
