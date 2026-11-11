"""A measurement plan with several reading times a day, on PostgreSQL."""

from datetime import datetime, timezone

import pytest

from app.clock import ManualClock
from app.database import db
from integration_tests.helpers import offline_circle
from integration_tests.test_measurements import signed_in


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


@pytest.fixture
def evening(database_app, monkeypatch):
    """28 October 2026 (a Wednesday), 20:00 in Riyadh."""
    clock = ManualClock(datetime(2026, 10, 28, 17, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    return clock


def plan(times, **changes):
    return {
        "kind": "glucose",
        "times": times,
        "weekdays": [3],
        "starts_on": "2026-10-28",
        "missed_after_minutes": 60,
        "glucose_low": 80,
        "glucose_high": 140,
        **changes,
    }


TWO_TIMES = [
    {"time_of_day": "07:00", "measurement_state": "fasting"},
    {"time_of_day": "14:00", "measurement_state": "after_meal"},
]


def reading(value, measured_at="2026-10-28T11:05:00+00:00"):
    return {
        "kind": "glucose",
        "outcome": "read",
        "measured_at": measured_at,
        "glucose_value": value,
        "conditions": ["after_meal"],
    }


def test_each_reading_time_is_its_own_task(
    database_app, database, account, evening
):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    base = f"/api/v1/circles/{circle.id}"

    created = client.post(
        f"{base}/measurement-plans", headers=headers, json=plan(TWO_TIMES)
    )
    assert created.status_code == 201, created.json
    version = created.json["measurement_plan"]["version"]
    assert version["times"] == TWO_TIMES

    def tasks():
        response = client.get(
            f"{base}/measurement-occurrences",
            headers=headers,
            query_string={"from": "2026-10-28", "to": "2026-10-28"},
        )
        return [
            (item["time_of_day"], item["measurement_state"], item["status"])
            for item in response.json["measurement_occurrences"]
        ]

    assert tasks() == [
        ("07:00", "fasting", "missed"),
        ("14:00", "after_meal", "missed"),
    ]

    path = f"{base}/measurement-readings/{version['id']}/2026-10-28"
    # Two times that day: the app must say which one.
    unnamed = client.put(path, headers=headers, json=reading(120))
    assert unnamed.status_code == 422
    assert unnamed.json["error"]["code"] == "measurement_time_required"
    wrong = client.put(
        path,
        headers=headers,
        json=reading(120),
        query_string={"time": "09:00"},
    )
    assert wrong.status_code == 404

    saved = client.put(
        path,
        headers=headers,
        json=reading(120),
        query_string={"time": "14:00"},
    )
    assert saved.status_code == 200, saved.json
    assert saved.json["measurement_reading"]["scheduled_time"] == "14:00"
    assert tasks() == [
        ("07:00", "fasting", "missed"),
        ("14:00", "after_meal", "read"),
    ]
    again = client.put(
        path,
        headers=headers,
        json=reading(121),
        query_string={"time": "14:00"},
    )
    assert again.status_code == 409


def test_a_same_day_edit_changes_the_times(
    database_app, database, account, evening
):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    base = f"/api/v1/circles/{circle.id}"
    created = client.post(
        f"{base}/measurement-plans",
        headers=headers,
        json=plan([
            {"time_of_day": "07:00", "measurement_state": "fasting"}
        ]),
    )
    plan_id = created.json["measurement_plan"]["id"]

    edited = client.put(
        f"{base}/measurement-plans/{plan_id}",
        headers=headers,
        json={**plan(TWO_TIMES), "expected_version_number": 1},
    )

    assert edited.status_code == 200, edited.json
    version = edited.json["measurement_plan"]["version"]
    assert version["version_number"] == 1
    assert version["times"] == TWO_TIMES
