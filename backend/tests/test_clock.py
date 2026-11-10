"""The patient's zone rules in `app.clock`, with real DST."""

from datetime import date, datetime, time, timedelta, timezone
from types import SimpleNamespace

import pytest

from app.clock import (
    DEFAULT_ZONE,
    is_zone,
    latest_today,
    local_moment,
    patient_today,
    patient_zone,
)
from app.medications.occurrence_builder import _timing_state

LONDON = SimpleNamespace(time_zone="Europe/London")
RIYADH = SimpleNamespace(time_zone=DEFAULT_ZONE)
AUCKLAND = SimpleNamespace(time_zone="Pacific/Auckland")


@pytest.mark.parametrize(
    "name, known",
    [
        ("Asia/Riyadh", True),
        ("Europe/London", True),
        ("America/St_Johns", True),
        ("UTC+3", False),
        ("", False),
        ("Mars/Olympus", False),
        ("../etc/passwd", False),
        # A folder of the zone database, not a zone.
        ("America", False),
    ],
)
def test_only_iana_zones_are_zones(name, known):
    assert is_zone(name) is known


def test_the_day_is_the_patients_own():
    """One instant is three different days for three patients."""
    now = datetime(2026, 10, 15, 22, 30, tzinfo=timezone.utc)

    assert patient_today(LONDON, now) == date(2026, 10, 15)
    assert patient_today(RIYADH, now) == date(2026, 10, 16)
    assert patient_today(AUCKLAND, now) == date(2026, 10, 16)
    assert patient_zone(LONDON).key == "Europe/London"


def test_a_dose_keeps_its_wall_clock_time_across_dst():
    """08:00 in London is 07:00 UTC in summer and 08:00 UTC in winter;
    a fixed offset would move it by an hour on one side."""
    before = local_moment(date(2026, 3, 28), time(8), patient_zone(LONDON))
    after = local_moment(date(2026, 3, 29), time(8), patient_zone(LONDON))

    assert before == datetime(2026, 3, 28, 8, tzinfo=timezone.utc)
    assert after == datetime(2026, 3, 29, 7, tzinfo=timezone.utc)
    assert after - before == timedelta(hours=23)


def test_a_time_skipped_by_dst_lands_an_hour_later():
    """01:30 does not exist in London on 29 March 2026."""
    moment = local_moment(date(2026, 3, 29), time(1, 30), patient_zone(LONDON))

    assert moment == datetime(2026, 3, 29, 1, 30, tzinfo=timezone.utc)
    assert moment.astimezone(patient_zone(LONDON)).hour == 2


def test_minutes_after_a_dose_are_real_minutes_in_the_repeated_hour():
    """01:30 on 25 October 2026 happens twice in London; the dose is the
    first one, and it is missed 30 real minutes later, not 90."""
    scheduled = local_moment(
        date(2026, 10, 25), time(1, 30), patient_zone(LONDON)
    )

    def state(minutes):
        return _timing_state(
            scheduled, scheduled + timedelta(minutes=minutes), None, 30
        )

    assert scheduled == datetime(2026, 10, 25, 0, 30, tzinfo=timezone.utc)
    assert state(-1) == "upcoming"
    assert state(14) == "due"
    assert state(29) == "late"
    assert state(30) == "missed"


def test_latest_today_is_the_day_at_utc_plus_14():
    now = datetime(2026, 10, 15, 9, 59, tzinfo=timezone.utc)

    assert latest_today(now) == date(2026, 10, 15)
    assert latest_today(now + timedelta(minutes=1)) == date(2026, 10, 16)
