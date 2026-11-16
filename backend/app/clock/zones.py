"""The patient's zone and calendar day, and moments in UTC."""

from datetime import date, datetime, time, timedelta, timezone
from typing import TYPE_CHECKING
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

if TYPE_CHECKING:
    from app.models import CareCircle

# The zone of every patient made before zones were stored (migration 0030),
# and of a Saudi city when the app sends none.
DEFAULT_ZONE = "Asia/Riyadh"


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


def patient_zone(patient: "CareCircle") -> ZoneInfo:
    """The zone where the patient lives, with its real DST rules."""
    return ZoneInfo(patient.time_zone)


def patient_today(patient: "CareCircle", now: datetime) -> date:
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


def as_utc(moment: datetime | None) -> datetime | None:
    """`moment` (with its offset) as the same instant in UTC.

    A time a phone sends keeps the phone's offset (`+03:00`); the database
    hands it back in UTC. Saving it in UTC makes the answer to a save equal
    to every later read of the same record.
    """
    return moment.astimezone(timezone.utc) if moment is not None else None
