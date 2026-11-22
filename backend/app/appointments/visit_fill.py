"""Whether a visit's paper («ورقة الزيارة») has anything in it: a word in
its summary, its recommendations or its follow-up, or a voice note. A visit
with a filled paper stays «حضرت» (outcomes.py)."""

from collections.abc import Iterable
from uuid import UUID

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.models import AppointmentVisit


def _written(column):
    """The text column holds more than spaces."""
    return func.coalesce(func.btrim(column), "") != ""


def filled_visits(
    session: Session, appointment_ids: Iterable[UUID]
) -> set[UUID]:
    """Those of the appointments whose visit paper has something in it."""
    ids = list(appointment_ids)
    if not ids:
        return set()
    return set(
        session.scalars(
            select(AppointmentVisit.appointment_id).where(
                AppointmentVisit.appointment_id.in_(ids),
                or_(
                    _written(AppointmentVisit.summary),
                    _written(AppointmentVisit.recommendations),
                    _written(AppointmentVisit.follow_up),
                    AppointmentVisit.audio.is_not(None),
                ),
            )
        )
    )


def visit_filled(session: Session, appointment_id: UUID) -> bool:
    """Whether this appointment's visit paper has something in it."""
    return appointment_id in filled_visits(session, [appointment_id])
