"""Telling each missed task once: a claim in `notification_log`, keyed
by the occurrence."""

from datetime import date, time
from uuid import UUID

from sqlalchemy.exc import IntegrityError

from app.database import transaction
from app.models import NotificationLog


def claim_once(
    kind: str, target_id: str, scheduled_on: str, time_of_day: str | None
) -> bool:
    """True the first time this notification is claimed; False on a
    repeat."""
    try:
        with transaction() as session:
            session.add(NotificationLog(
                kind=kind,
                target_id=UUID(target_id),
                scheduled_on=date.fromisoformat(scheduled_on),
                time_of_day=(
                    time.fromisoformat(time_of_day) if time_of_day else None
                ),
            ))
    except IntegrityError:
        return False
    return True


def occurrence_key(task_id: str, occurrence: dict) -> tuple:
    """An occurrence's key in `put_off_until`."""
    return (
        task_id,
        occurrence["scheduled_on"],
        occurrence["time_of_day"][:5],
    )
