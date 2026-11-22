"""`scan_reminders`: a circle's reminders whose time came, each sent once."""

from datetime import datetime, timedelta
from uuid import UUID

from app import metrics
from app.background import run_at
from app.clock import patient_zone
from app.database import transaction
from app.extensions import get_clock
from app.measurements.queries import MeasurementQueries
from app.medications.queries import MedicationQueries
from app.push.scheduled.audience import circle_patient, read_audience
from app.push.scheduled.claims import claim_once
from app.push.scheduled.reminders.appointments import appointment_reminders
from app.push.scheduled.reminders.reminder import send_reminder
from app.push.scheduled.reminders.switch import listening, reminders_on
from app.push.scheduled.reminders.tasks import (
    dose_reminders,
    measurement_reminders,
)

# A reminder not sent this soon after its time (the server was away) is
# not sent any more: the push of the missed task follows.
LATE_AT_MOST = timedelta(minutes=5)


def scan_reminders(
    circle_id: UUID, now: datetime, ahead: timedelta = timedelta(0)
) -> None:
    """Send each reminder of the circle whose time came in the last
    `LATE_AT_MOST`, once; and set a timer at each moment in the next
    `ahead`, so its reminder comes on its minute."""
    if not reminders_on():
        return
    with transaction() as session:
        patient = circle_patient(session, circle_id)
        if patient is None:
            return
        audience = read_audience(session, patient)
        ears = listening(session, audience.names)
        # No phone in the circle asked for them: nothing more to read.
        if not ears:
            return
        zone = patient_zone(patient)
        first = (now - LATE_AT_MOST).astimezone(zone).date()
        last = (now + ahead).astimezone(zone).date()
        doses = MedicationQueries(session, now).occurrences(
            circle_id, first, last
        )
        readings = MeasurementQueries(session, now).occurrences(
            circle_id, first, last
        )
        reminders = [
            *dose_reminders(circle_id, doses, zone),
            *measurement_reminders(circle_id, readings, zone),
            *appointment_reminders(session, patient, zone, first, last),
        ]
    coming = set()
    for reminder in reminders:
        if reminder.at > now:
            if reminder.at <= now + ahead:
                coming.add(reminder.at)
        elif now - reminder.at <= LATE_AT_MOST and claim_once(
            *reminder.claim
        ):
            metrics.increment(f"reminder.{reminder.kind}")
            send_reminder(reminder, circle_id, audience, ears)
    for at in sorted(coming):
        run_at(at, now, remind_on_time, circle_id)


def remind_on_time(circle_id: UUID) -> None:
    """A timer's job: the circle's reminders whose moment has just come,
    read again now, so a task recorded meanwhile is not reminded of."""
    scan_reminders(circle_id, get_clock().now())
