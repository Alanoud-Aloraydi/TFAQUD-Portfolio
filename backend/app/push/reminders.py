"""The reminders at a task's time, sent by the server: one at each dose
and reading time not recorded yet, not missed and not put off, and the
visit reminders; `scan_reminders` sends a circle's due ones, each once."""

from datetime import date, datetime, time, timedelta
from functools import partial
from uuid import UUID
from zoneinfo import ZoneInfo

from app import metrics
from app.background import run_at
from app.clock import local_moment, patient_zone
from app.database import transaction
from app.extensions import get_clock
from app.measurements.queries import MeasurementQueries
from app.medications.queries import MedicationQueries
from app.push.audience import circle_patient, claim_once, read_audience
from app.push.notify import dose_target, measurement_target
from app.push.reminder import (
    Reminder,
    dose_payload,
    listening,
    measurement_payload,
    reminders_on,
    send_reminder,
)
from app.push.texts import dose_words, measurement_words
from app.push.visit_reminders import appointment_reminders


def dose_reminders(
    circle_id: UUID, occurrences: list[dict], zone: ZoneInfo
) -> list[Reminder]:
    """The doses' reminders, from the doses as the API answers them."""
    return [
        _dose(circle_id, item, zone)
        for item in occurrences
        if item["record"] is None
        and item["timing_state"] != "missed"
        and not item.get("snooze")
    ]


def measurement_reminders(
    circle_id: UUID, occurrences: list[dict], zone: ZoneInfo
) -> list[Reminder]:
    """The reading times' reminders, from the tasks as the API answers
    them."""
    return [
        _reading(circle_id, item, zone)
        for item in occurrences
        if item["reading"] is None
        and item["status"] in ("upcoming", "due")
        and not item.get("snooze")
    ]


def _dose(circle_id: UUID, item: dict, zone: ZoneInfo) -> Reminder:
    day = date.fromisoformat(item["scheduled_on"])
    wall = item["time_of_day"]
    schedule = item["schedule_id"]
    return Reminder(
        at=local_moment(day, time.fromisoformat(wall), zone),
        claim=("dose_reminder", schedule, item["scheduled_on"], wall),
        kind="dose_reminder",
        target=dose_target(circle_id, schedule, day),
        words=partial(dose_words, item["name"]),
        payload=partial(dose_payload, circle_id, schedule, day, item["name"]),
        snoozable=True,
    )


def _reading(circle_id: UUID, item: dict, zone: ZoneInfo) -> Reminder:
    day = date.fromisoformat(item["scheduled_on"])
    wall = item["time_of_day"]
    version = item["plan_version_id"]
    return Reminder(
        at=local_moment(day, time.fromisoformat(wall), zone),
        claim=("measurement_reminder", version, item["scheduled_on"], wall),
        kind="measurement_reminder",
        target=measurement_target(circle_id, version, day, wall),
        words=partial(measurement_words, item["kind"]),
        payload=partial(
            measurement_payload, circle_id, version, wall, day, item["kind"]
        ),
        snoozable=True,
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
