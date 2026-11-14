"""Readings are judged by fixed normal ranges, by meal state and the
patient's conditions (0049)."""

from datetime import datetime, timezone

import pytest
from sqlalchemy.orm import Session

from app.clock import ManualClock
from app.database import db
from app.models import PatientCondition
from integration_tests.helpers import offline_circle
from integration_tests.test_measurement_times import plan
from integration_tests.test_measurements import signed_in


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


@pytest.fixture
def patient(database_app, database, account, monkeypatch):
    """A circle at 20:00 in Riyadh on 28 October 2026 (a Wednesday), and a
    way to call its endpoints and to give its patient conditions."""
    clock = ManualClock(datetime(2026, 10, 28, 17, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    base = f"/api/v1/circles/{circle.id}"

    def call(method, path, **kwargs):
        return getattr(client, method)(
            f"{base}{path}", headers=headers, **kwargs
        )

    def diagnose(*codes):
        with Session(database) as session:
            session.add_all(
                PatientCondition(care_circle_id=circle.id, code=code)
                for code in codes
            )
            session.commit()

    call.diagnose = diagnose
    return call


def _free(value, *conditions):
    return {
        "kind": "glucose",
        "outcome": "read",
        "measured_at": "2026-10-28T16:00:00+00:00",
        "glucose_value": value,
        "conditions": list(conditions),
    }


def test_the_ranges_follow_the_medical_file(patient):
    general = patient("get", "/measurement-ranges")
    assert general.status_code == 200, general.json
    value = general.json["measurement_ranges"]
    assert value["conditions"] == []
    assert [
        (item["kind"], item["profile"], item["state"])
        for item in value["ranges"]
    ] == [
        ("glucose", "general", "fasting"),
        ("glucose", "general", "after_meal"),
        ("blood_pressure", "general", None),
    ]
    assert value["ranges"][0]["bands"][1] == {
        "level": "normal", "glucose_low": 70, "glucose_high": 100,
    }

    patient.diagnose("diabetes", "hypertension", "asthma")
    value = patient("get", "/measurement-ranges").json["measurement_ranges"]

    assert value["conditions"] == ["diabetes", "hypertension"]
    assert [item["profile"] for item in value["ranges"]] == [
        "diabetes", "diabetes", "hypertension",
    ]
    assert value["ranges"][2]["bands"][1]["systolic_high"] == 130


def test_a_reading_outside_a_plan_needs_no_target(patient):
    saved = patient(
        "post", "/measurement-readings", json=_free(150, "after_meal")
    )

    assert saved.status_code == 201, saved.json
    answer = saved.json["measurement_reading"]
    assert answer["level"] == "elevated"
    assert answer["normal_range"]["glucose_high"] == 140


def test_diabetes_changes_the_level_of_the_same_value(patient):
    patient.diagnose("diabetes")

    saved = patient(
        "post", "/measurement-readings", json=_free(150, "after_meal")
    )

    answer = saved.json["measurement_reading"]
    assert answer["level"] == "normal"
    assert answer["normal_range"] == {
        "profile": "diabetes", "state": "after_meal",
        "glucose_low": 70, "glucose_high": 180,
    }


def test_a_task_without_a_meal_state_uses_its_planned_one(patient):
    created = patient(
        "post",
        "/measurement-plans",
        json=plan([{"time_of_day": "07:00", "measurement_state": "fasting"}]),
    )
    assert created.status_code == 201, created.json
    version = created.json["measurement_plan"]["version"]
    assert "glucose_low" not in version

    saved = patient(
        "put",
        f"/measurement-readings/{version['id']}/2026-10-28",
        json={**_free(120), "measured_at": "2026-10-28T04:05:00+00:00"},
    )

    assert saved.status_code == 200, saved.json
    answer = saved.json["measurement_reading"]
    assert answer["level"] == "elevated"
    assert answer["normal_range"]["state"] == "fasting"
    listed = patient(
        "get",
        "/measurement-readings",
        query_string={"from": "2026-10-28", "to": "2026-10-28"},
    ).json["measurement_readings"]
    assert listed[0]["level"] == "elevated"


def test_only_a_reading_outside_its_range_is_followed_up(patient):
    normal = patient(
        "post", "/measurement-readings", json=_free(95, "fasting")
    ).json["measurement_reading"]
    high = patient(
        "post", "/measurement-readings", json=_free(210, "after_meal")
    ).json["measurement_reading"]

    refused = patient(
        "post", f"/measurement-readings/{normal['id']}/follow-up"
    )
    followed = patient(
        "post", f"/measurement-readings/{high['id']}/follow-up"
    )

    assert refused.status_code == 422
    assert refused.json["error"]["code"] == "measurement_within_target"
    assert followed.status_code == 200, followed.json
    assert followed.json["measurement_reading"]["followed_up_at"]
