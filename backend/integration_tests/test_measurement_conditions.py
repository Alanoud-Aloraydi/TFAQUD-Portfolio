"""Planned measurement state is separate from actual reading conditions."""

from datetime import datetime, timezone

import pytest

from app.clock import ManualClock
from app.database import db
from integration_tests.helpers import offline_circle
from integration_tests.test_measurement_times import plan
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


@pytest.fixture
def circle_api(database_app, database, account, evening):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    base = f"/api/v1/circles/{circle.id}"

    def call(method, path, **kwargs):
        return getattr(client, method)(
            f"{base}{path}", headers=headers, **kwargs
        )

    return call


BP = {
    "kind": "blood_pressure",
}


def test_a_glucose_time_keeps_its_measurement_state(circle_api):
    created = circle_api(
        "post",
        "/measurement-plans",
        json=plan([
            {"time_of_day": "07:00", "measurement_state": "fasting"},
            {"time_of_day": "14:00", "measurement_state": "after_meal"},
        ]),
    )

    assert created.status_code == 201, created.json
    version = created.json["measurement_plan"]["version"]
    assert version["times"] == [
        {"time_of_day": "07:00", "measurement_state": "fasting"},
        {"time_of_day": "14:00", "measurement_state": "after_meal"},
    ]
    tasks = circle_api(
        "get",
        "/measurement-occurrences",
        query_string={"from": "2026-10-28", "to": "2026-10-28"},
    ).json["measurement_occurrences"]
    assert [item["measurement_state"] for item in tasks] == [
        "fasting",
        "after_meal",
    ]


def test_blood_pressure_plan_has_no_measurement_state(circle_api):
    created = circle_api(
        "post",
        "/measurement-plans",
        json=plan(
            [{"time_of_day": "08:00"}],
            **BP,
        ),
    )

    assert created.status_code == 201, created.json
    version = created.json["measurement_plan"]["version"]
    assert version["times"][0]["measurement_state"] is None


@pytest.mark.parametrize(
    "kind, measurement_state",
    [
        ("blood_pressure", "fasting"),
        ("glucose", None),
        ("glucose", "bedtime"),
    ],
)
def test_measurement_states_that_do_not_fit_are_refused(
    circle_api, kind, measurement_state
):
    body = plan(
        [{"time_of_day": "08:00", "measurement_state": measurement_state}],
        **(BP if kind == "blood_pressure" else {}),
    )

    created = circle_api("post", "/measurement-plans", json=body)

    assert created.status_code == 422


def test_a_reading_has_several_conditions(circle_api):
    saved = circle_api(
        "post",
        "/measurement-readings",
        json={
            "kind": "glucose",
            "outcome": "read",
            "measured_at": "2026-10-28T16:00:00+00:00",
            "glucose_value": 150,
            "conditions": ["after_meal", "stress", "other"],
        },
    )

    assert saved.status_code == 201, saved.json
    reading = saved.json["measurement_reading"]
    assert reading["conditions"] == ["after_meal", "stress", "other"]


def test_a_reading_sends_one_shape_only(circle_api):
    both = circle_api(
        "post",
        "/measurement-readings",
        json={
            "kind": "glucose",
            "outcome": "read",
            "measured_at": "2026-10-28T16:00:00+00:00",
            "glucose_value": 150,
            "conditions": ["fasting"],
            "measurement_state": "fasting",
        },
    )

    assert both.status_code == 422


def test_other_says_what_it_was(circle_api):
    reading = {
        "kind": "blood_pressure",
        "outcome": "read",
        "measured_at": "2026-10-28T16:00:00+00:00",
        "systolic_value": 128,
        "diastolic_value": 82,
    }

    saved = circle_api(
        "post",
        "/measurement-readings",
        json={
            **reading,
            "conditions": ["other"],
            "other_text": "  بعد القهوة ",
        },
    )

    assert saved.status_code == 201, saved.json
    answer = saved.json["measurement_reading"]
    assert answer["conditions"] == ["other"]
    assert answer["other_text"] == "بعد القهوة"
    # Words without «أخرى» are refused.
    assert circle_api(
        "post",
        "/measurement-readings",
        json={
            **reading,
            "conditions": ["stress"],
            "other_text": "بعد القهوة",
        },
    ).status_code == 422
