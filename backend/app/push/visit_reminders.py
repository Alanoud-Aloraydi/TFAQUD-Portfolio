"""The reminders of the visits still to come: a day before and at the
lead chosen for each, to the patient and the members going with them (or
the leader, for a patient without a phone when nobody goes)."""

from datetime import date, datetime, timedelta
from functools import partial
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.circles.leader import leader_id
from app.clock import as_utc, local_moment
from app.models import CareCircle
from app.models.appointment import Appointment, AppointmentCompanion
from app.push.notify import appointment_target
from app.push.reminder import Reminder, appointment_payload
from app.push.texts import TODAY, TOMORROW, after, visit_body, visit_words


DAY_BEFORE = timedelta(days=1)

# How long after a visit is saved it is said (`appointmentSavedLead`).
SAVED_LEAD = timedelta(seconds=30)

# A near reminder this close after the saving says it anyway.
SOON_ENOUGH = timedelta(minutes=10)


def visit_moments(visit, zone: ZoneInfo) -> list[tuple[str, datetime]]:
    """The visit's reminders as (lead, moment): "day_before", "soon" and
    "today" (the one said after a late saving)."""
    moment = local_moment(visit.scheduled_on, visit.time_of_day, zone)
    saved = as_utc(visit.updated_at)
    soon = moment - timedelta(minutes=visit.reminder_lead_minutes)
    moments = [
        (lead, at)
        for lead, at in (("day_before", moment - DAY_BEFORE), ("soon", soon))
        if at > saved
    ]
    if saved > moment - DAY_BEFORE:
        at = saved + SAVED_LEAD
        soon_comes = at < soon and soon - at < SOON_ENOUGH
        if at < moment and not soon_comes:
            moments.append(("today", at))
    return moments


def visit_goers(
    session: Session, patient: CareCircle, visit_ids: list[UUID]
) -> dict[UUID, frozenset[UUID]]:
    """Each of the visits' goers, by its id, read in the caller's
    transaction."""
    going: dict[UUID, set[UUID]] = {visit_id: set() for visit_id in visit_ids}
    for visit_id, account_id in session.execute(
        select(
            AppointmentCompanion.appointment_id,
            AppointmentCompanion.account_id,
        ).where(AppointmentCompanion.appointment_id.in_(visit_ids))
    ):
        going[visit_id].add(account_id)
    stands_in = (
        leader_id(session, patient) if patient.account_id is None else None
    )
    return {
        visit_id: _goers(companions, patient, stands_in)
        for visit_id, companions in going.items()
    }


def _goers(
    companions: set[UUID], patient: CareCircle, stands_in: UUID | None
) -> frozenset[UUID]:
    """The patient and the companions; the leader of a patient without a
    phone when nobody goes with them."""
    goers = set(companions)
    if patient.account_id is not None:
        goers.add(patient.account_id)
    elif not goers and stands_in is not None:
        goers.add(stands_in)
    return frozenset(goers)


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
