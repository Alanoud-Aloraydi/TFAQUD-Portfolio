"""The reminders at a dose's and a reading's time: one at each that is not
recorded yet, not missed, and not put off. A task put off is reminded of at
its new time instead, by the phone of whoever put it off and by the server
to the others (app/snoozes/due.py)."""

from datetime import date, time
from functools import partial
from uuid import UUID
from zoneinfo import ZoneInfo

from app.clock import local_moment
from app.push.scheduled.reminders.payloads import (
    dose_payload,
    measurement_payload,
)
from app.push.scheduled.reminders.reminder import Reminder
from app.push.scheduled.reminders.words import dose_words, measurement_words
from app.push.targets import dose_target, measurement_target


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
