"""What a reminder tells the app: the payload the phone's own reminder
carries (reminder_payloads.dart), so the app opens a reminder from the
server, and puts it off with «ذكّرني لاحقًا», the way it does its own.

A dose's and a reading's hold their kind and circle, the words shown, and
which task it is (its snooze key and subject); a visit's, its circle and
its id."""

from datetime import date
from uuid import UUID

# Between the parts of a payload (reminder_payload_parts.dart).
_PARTS = "\x1f"

# The iOS category of a reminder that can be put off, with its button
# «ذكّرني لاحقًا»; the app registers it (reminder_channel.dart).
SNOOZE_CATEGORY = "tafaqod.reminder"


def _day(day: date) -> str:
    """A day as the app's snooze keys write it: «2026-11-5», no zeros."""
    return f"{day.year}-{day.month}-{day.day}"


def dose_payload(
    circle_id: UUID, schedule_id: str, day: date, medicine: str,
    title: str, body: str,
) -> str:
    """A dose's (`doseSnoozeKey`; its subject is the medicine's name)."""
    key = f"{circle_id}|{schedule_id}|{_day(day)}"
    return _PARTS.join((f"dose:{circle_id}", title, body, key, medicine))


def measurement_payload(
    circle_id: UUID, version_id: str, wall_time: str, day: date, kind: str,
    title: str, body: str,
) -> str:
    """A reading time's (`measurementSnoozeKey`; its subject is the app's
    name of the kind, «bp» for blood_pressure)."""
    key = f"{circle_id}|measurement|{version_id}|{wall_time}|{_day(day)}"
    subject = "bp" if kind == "blood_pressure" else kind
    head = f"measurement:{circle_id}"
    return _PARTS.join((head, title, body, key, subject))


def appointment_payload(
    circle_id: UUID, appointment_id: UUID, title: str, body: str
) -> str:
    """A visit's: its circle, then «@» and its id (`appointmentIdMark`);
    it cannot be put off, so it carries no words."""
    return f"appointment:{circle_id}@{appointment_id}"
