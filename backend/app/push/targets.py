"""Which item a push is about, put in its data beside `kind`, so a tap on
it opens that very item: a dose, a reading or a visit on «اليوم» of its
circle, an invitation or a request on the bell, or a circle that is ready.

Ids and days are text, as the API writes them (a day as YYYY-MM-DD, a
time of day as HH:MM)."""

from datetime import date
from uuid import UUID

Target = tuple[tuple[str, str], ...]


def dose_target(circle_id: UUID | str, schedule_id, day) -> Target:
    """A dose: its circle, its schedule and its day."""
    return (
        ("circle_id", str(circle_id)),
        ("schedule_id", str(schedule_id)),
        ("scheduled_on", _day(day)),
    )


def measurement_target(
    circle_id: UUID | str, version_id, day, time_of_day: str
) -> Target:
    """A reading time: its circle, its plan's version, its day and time."""
    return (
        ("circle_id", str(circle_id)),
        ("plan_version_id", str(version_id)),
        ("scheduled_on", _day(day)),
        ("time_of_day", time_of_day),
    )


def appointment_target(circle_id: UUID | str, appointment_id) -> Target:
    """A visit: its circle and its id."""
    return (
        ("circle_id", str(circle_id)),
        ("appointment_id", str(appointment_id)),
    )


def circle_target(circle_id: UUID | str) -> Target:
    """A circle, opened on its «اليوم»."""
    return (("circle_id", str(circle_id)),)


def request_target(request_id) -> Target:
    """A circle request on the bell."""
    return (("request_id", str(request_id)),)


def invitation_target(invitation_id) -> Target:
    """An invitation on the bell."""
    return (("invitation_id", str(invitation_id)),)


def _day(day) -> str:
    return day.isoformat() if isinstance(day, date) else str(day)
