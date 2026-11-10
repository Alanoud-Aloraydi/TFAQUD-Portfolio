"""A clock the app asks for the time, so tests can move time forward.

Code never calls `datetime.now()` directly. It calls `clock.now()`.

  SystemClock  - the real time. Used by the running server.
  ManualClock  - time that only moves when told to. Used by tests and by
                 scripts/walkthrough.py, which is how token expiry is checked
                 without waiting 15 minutes or 30 days.

Every calendar rule of a circle (schedules, "today", birth dates) follows
the patient's own IANA zone, `Patient.time_zone`, whoever records and
wherever their phone is. `patient_zone`, `patient_today` and `local_moment`
are the only ways the server reads it; `latest_today` is the bound for a
date that has no patient yet.
"""

from datetime import date, datetime, time, timedelta, timezone
from typing import TYPE_CHECKING, Protocol
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

if TYPE_CHECKING:
    from app.models import Patient

# The zone of every patient made before zones were stored (migration 0030),
# and of a Saudi city when the app sends none.
DEFAULT_ZONE = "Asia/Riyadh"


class Clock(Protocol):
    """Anything with now(): SystemClock or ManualClock."""

    def now(self) -> datetime: ...


def is_zone(name: str) -> bool:
    """True when `name` is an IANA zone this server knows (e.g.
    "Europe/London"); "UTC+3" style offsets, blanks and folder names of
    the zone database ("America") are not zones."""
    try:
        ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError, OSError):
        # OSError: a folder of the database, which some Python versions
        # try to open as a file instead of reporting it unknown.
        return False
    return True


def patient_zone(patient: "Patient") -> ZoneInfo:
    """The zone where the patient lives, with its real DST rules."""
    return ZoneInfo(patient.time_zone)


def patient_today(patient: "Patient", now: datetime) -> date:
    """The patient's calendar day at the instant `now`."""
    return now.astimezone(patient_zone(patient)).date()


def latest_today(now: datetime) -> date:
    """The newest calendar day anywhere on Earth at `now` (UTC+14).

    For a date with no patient yet, such as the account's own birth date
    at onboarding: a date that is already today somewhere is not in the
    future, wherever the person lives."""
    return now.astimezone(timezone(timedelta(hours=14))).date()


def local_moment(day: date, time_of_day: time, zone: ZoneInfo) -> datetime:
    """The UTC instant of the wall-clock `time_of_day` on `day` in `zone`.

    Returned in UTC so that adding minutes and comparing with `now` count
    real time across a DST change; two datetimes sharing one zone compare
    by wall clock instead. A time skipped by a DST jump lands one hour
    later (PEP 495, fold=0)."""
    return datetime.combine(day, time_of_day, tzinfo=zone).astimezone(
        timezone.utc
    )


class SystemClock:
    """The real time, in UTC."""

    def now(self) -> datetime:
        return datetime.now(timezone.utc)


class ManualClock:
    """A time that moves only when told to; used by tests."""

    def __init__(self, start: datetime | None = None):
        self._now = start or datetime(
            2026, 10, 15, 12, 0, 0, tzinfo=timezone.utc
        )

    def now(self) -> datetime:
        return self._now

    def advance(self, **kwargs) -> None:
        """Move forward: advance(minutes=20) or advance(days=31)."""
        self._now += timedelta(**kwargs)
