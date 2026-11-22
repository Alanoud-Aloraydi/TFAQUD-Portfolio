"""The reminders of the visits still to come: when (moments.py), to whom
(goers.py), and in what words (visit_words.py)."""

from datetime import date, timedelta
from functools import partial
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import CareCircle
from app.models.appointment import Appointment
from app.push.scheduled.reminders.goers import visit_goers
from app.push.scheduled.reminders.moments import visit_moments
from app.push.scheduled.reminders.payloads import appointment_payload
from app.push.scheduled.reminders.reminder import Reminder
from app.push.scheduled.reminders.visit_words import (
    TODAY,
    TOMORROW,
    after,
    visit_body,
    visit_words,
)
from app.push.targets import appointment_target


def appointment_reminders(
    session: Session, patient: CareCircle, zone: ZoneInfo,
    first: date, last: date,
) -> list[Reminder]:
    """The reminders of the patient's visits from `first` to the day after
    `last` (a reminder a day before comes the day before its visit), read
    in the caller's transaction."""
    visits = list(session.scalars(select(Appointment).where(
        Appointment.care_circle_id == patient.id,
        Appointment.status == "scheduled",
        Appointment.marked_missed.is_(False),
        Appointment.scheduled_on.between(first, last + timedelta(days=1)),
    )))
    if not visits:
        return []
    goers = visit_goers(session, patient, [visit.id for visit in visits])
    return [
        _reminder(patient.id, visit, zone, lead, at, goers[visit.id])
        for visit in visits
        for lead, at in visit_moments(visit, zone)
    ]


def _reminder(circle_id, visit, zone, lead, at, to) -> Reminder:
    # «غدًا» a day before; «اليوم», or «غدًا» for a visit saved late the
    # day before it; «بعد ساعة» at its lead.
    when = {
        "day_before": TOMORROW,
        "soon": after(visit.reminder_lead_minutes),
        "today": (
            TODAY
            if at.astimezone(zone).date() == visit.scheduled_on
            else TOMORROW
        ),
    }[lead]
    return Reminder(
        at=at,
        claim=(
            f"appointment_{lead}",
            str(visit.id),
            visit.scheduled_on.isoformat(),
            visit.time_of_day.strftime("%H:%M"),
        ),
        kind="appointment_reminder",
        target=appointment_target(circle_id, visit.id),
        words=partial(visit_words, when, visit_body(visit)),
        payload=partial(appointment_payload, circle_id, visit.id),
        to=to,
    )
