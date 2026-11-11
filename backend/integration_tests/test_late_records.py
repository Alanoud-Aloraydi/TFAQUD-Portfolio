"""A task of the last two patient days can still be answered: the record
keeps the scheduled day and the real time it was done."""

from datetime import datetime, timedelta, timezone

import pytest

from app.clock import ManualClock
from app.database import db
from integration_tests.helpers import Api, error_code, offline_circle

EVERY_DAY = [1, 2, 3, 4, 5, 6, 7]


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


@pytest.fixture
def clock(database_app, monkeypatch):
    """9 November 2026, 07:00 in Riyadh (the test circle's patient zone)."""
    value = ManualClock(datetime(2026, 11, 9, 4, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", value)
    return value


def daily_plan():
    return {
        "name": "Metformin",
        "strength_value": "500",
        "strength_unit": "mg",
        "dosage_form": "tablet",
        "reason_for_use": "Diabetes",
        "instructions": None,
        "treatment_starts_on": "2026-11-09",
        "treatment_ends_on": None,
        "schedules": [
            {
                "time_of_day": "08:00",
                "dose_value": 1,
                "dose_unit": "tablet",
                "weekdays": EVERY_DAY,
                "instructions": None,
            }
        ],
    }


def test_a_dose_two_days_back_is_taken_late_on_its_own_day(
    database_app, database, account, clock
):
    owner = account()
    circle = offline_circle(database, owner)
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{circle.id}"
    plan = api.post(f"{base}/medication-plans", daily_plan()).get_json()
    schedule_id = plan["medication_plan"]["version"]["schedules"][0]["id"]

    clock.advance(days=2, hours=5)
    taken_at = clock.now() - timedelta(minutes=1)
    saved = api.put(
        f"{base}/medication-dose-records/{schedule_id}/2026-11-09",
        {"outcome": "taken", "taken_at": taken_at.isoformat()},
    )

    assert saved.status_code == 200, saved.get_json()
    listed = api.get(
        f"{base}/medication-occurrences?from=2026-11-09&to=2026-11-11"
    ).get_json()["medication_occurrences"]
    by_day = {item["scheduled_on"]: item["record"] for item in listed}
    assert by_day["2026-11-09"]["outcome"] == "taken"
    assert by_day["2026-11-10"] is None
    assert by_day["2026-11-11"] is None


def test_a_dose_of_a_day_that_has_not_come_is_refused(
    database_app, database, account, clock
):
    owner = account()
    circle = offline_circle(database, owner)
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{circle.id}"
    plan = api.post(f"{base}/medication-plans", daily_plan()).get_json()
    schedule_id = plan["medication_plan"]["version"]["schedules"][0]["id"]

    refused = api.put(
        f"{base}/medication-dose-records/{schedule_id}/2026-11-10",
        {"outcome": "skipped"},
    )

    assert error_code(refused, 422) == "future_dose_record"
