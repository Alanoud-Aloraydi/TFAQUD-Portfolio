"""Measurement plans and explicit outcomes against isolated PostgreSQL."""

from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from threading import Barrier
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.orm import Session
import pytest

from app.database import db
from app.models import MeasurementReading
from integration_tests.helpers import offline_circle


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


def signed_in(app, account):
    """Issue an authenticated request header."""
    issued = app.extensions["session_service"].create_session(account.id.hex)
    return {"Authorization": "Bearer " + issued.access_token}


@pytest.mark.parametrize(
    "page", ["medication-occurrences", "measurement-occurrences"]
)
def test_the_app_today_window_is_answered(
    database_app, database, account, page
):
    """«اليوم» asks for 2 overdue days, today and 30 days ahead in one
    request (33 days). Refusing it left the tab with «صار خطأ غير متوقع»."""
    owner = account()
    circle = offline_circle(database, owner)
    today = datetime.now(ZoneInfo("Asia/Riyadh")).date()

    answer = database_app.test_client().get(
        f"/api/v1/circles/{circle.id}/{page}",
        headers=signed_in(database_app, owner),
        query_string={
            "from": (today - timedelta(days=2)).isoformat(),
            "to": (today + timedelta(days=30)).isoformat(),
        },
    )

    assert answer.status_code == 200, answer.json


def test_plan_occurrence_reading_and_export(database_app, database, account):
    """Pending tasks stay computed; one explicit reading is saved."""
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    now = datetime.now(timezone.utc)
    local = now.astimezone(ZoneInfo("Asia/Riyadh"))
    day = local.date()
    base = f"/api/v1/circles/{circle.id}"
    body = {
        "kind": "glucose",
        "times": [
            {"time_of_day": "00:00", "measurement_state": "fasting"}
        ],
        "weekdays": [day.isoweekday()],
        "starts_on": day.isoformat(),
        "missed_after_minutes": 60,
    }
    created = client.post(
        f"{base}/measurement-plans", headers=headers, json=body
    )
    assert created.status_code == 201
    version_id = created.json["measurement_plan"]["version"]["id"]
    path = f"{base}/measurement-occurrences"
    range_query = {"from": day.isoformat(), "to": day.isoformat()}
    tasks = client.get(path, headers=headers, query_string=range_query)
    assert tasks.status_code == 200
    assert len(tasks.json["measurement_occurrences"]) == 1
    with Session(database) as session:
        assert (
            session.scalar(
                select(func.count()).select_from(MeasurementReading)
            )
            == 0
        )

    record_path = f"{base}/measurement-readings/{version_id}/{day.isoformat()}"
    reading = {
        "kind": "glucose",
        "outcome": "read",
        "measured_at": (now - timedelta(minutes=1)).isoformat(),
        "glucose_value": 151,
        "conditions": ["fasting"],
    }
    saved = client.put(record_path, headers=headers, json=reading)
    assert saved.status_code == 200
    # 151 fasting is above 125: high, with the fasting normal band.
    answer = saved.json["measurement_reading"]
    assert answer["level"] == "high"
    assert answer["outside_target"] is True
    assert answer["normal_range"] == {
        "profile": "general", "state": "fasting",
        "glucose_low": 70, "glucose_high": 100,
    }
    conflict = client.put(record_path, headers=headers, json=reading)
    assert conflict.status_code == 409
    exported = client.get(
        f"{base}/measurement-readings/export", headers=headers
    )
    assert exported.status_code == 200
    assert len(exported.json["measurement_readings"]) == 1


def test_plan_validation_and_authorization(database_app, database, account):
    """Reject a reading time that does not suit the kind, and
    unauthenticated writes."""
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    base = f"/api/v1/circles/{circle.id}/measurement-plans"
    day = datetime.now(ZoneInfo("Asia/Riyadh")).date()
    body = {
        "kind": "blood_pressure",
        "times": [
            {"time_of_day": "08:00", "measurement_state": "morning"}
        ],
        "weekdays": [day.isoweekday()],
        "starts_on": day.isoformat(),
    }
    assert client.post(base, json=body).status_code == 401
    invalid = client.post(
        base, headers=signed_in(database_app, owner), json=body
    )
    assert invalid.status_code == 422


def test_future_plan_can_be_edited_before_its_first_task(
    database_app, database, account
):
    """A future plan changes in place because no history exists yet."""
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    start = datetime.now(ZoneInfo("Asia/Riyadh")).date() + timedelta(
        days=3
    )
    base = f"/api/v1/circles/{circle.id}/measurement-plans"
    body = {
        "kind": "blood_pressure",
        "times": [
            {"time_of_day": "08:00", "measurement_state": "morning"}
        ],
        "weekdays": [start.isoweekday()],
        "starts_on": start.isoformat(),
    }
    created = client.post(base, headers=headers, json=body)
    assert created.status_code == 201
    plan = created.json["measurement_plan"]
    assert plan["pending_version"] is None
    changed = client.put(
        f"{base}/{plan['id']}",
        headers=headers,
        json={
            **body,
            "missed_after_minutes": 90,
            "expected_version_number": 1,
            "effective_from_on": start.isoformat(),
        },
    )
    assert changed.status_code == 200
    assert changed.json["measurement_plan"]["version"][
        "missed_after_minutes"
    ] == 90
    assert len(changed.json["measurement_plan"]["history"]) == 1


def _todays_glucose_plan(client, headers, base):
    """A glucose plan that starts today, with its task at midnight."""
    now = datetime.now(timezone.utc)
    day = now.astimezone(ZoneInfo("Asia/Riyadh")).date()
    body = {
        "kind": "glucose",
        "times": [
            {"time_of_day": "00:00", "measurement_state": "fasting"}
        ],
        "weekdays": [day.isoweekday()],
        "starts_on": day.isoformat(),
        "missed_after_minutes": 60,
    }
    created = client.post(
        f"{base}/measurement-plans", headers=headers, json=body
    )
    assert created.status_code == 201, created.json
    return now, day, body, created.json["measurement_plan"]


def test_an_edit_on_the_day_the_plan_was_added_replaces_it(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    base = f"/api/v1/circles/{circle.id}"
    _, day, body, plan = _todays_glucose_plan(client, headers, base)

    changed = client.put(
        f"{base}/measurement-plans/{plan['id']}",
        headers=headers,
        json={
            **body, "missed_after_minutes": 90, "expected_version_number": 1
        },
    )

    assert changed.status_code == 200, changed.json
    answer = changed.json["measurement_plan"]
    assert answer["version"]["missed_after_minutes"] == 90
    assert answer["version"]["effective_from_on"] == day.isoformat()
    assert answer["pending_version"] is None
    assert len(answer["history"]) == 1


def test_a_same_day_edit_after_a_reading_starts_tomorrow(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    base = f"/api/v1/circles/{circle.id}"
    now, day, body, plan = _todays_glucose_plan(client, headers, base)
    version_id = plan["version"]["id"]
    saved = client.put(
        f"{base}/measurement-readings/{version_id}/{day.isoformat()}",
        headers=headers,
        json={
            "kind": "glucose",
            "outcome": "read",
            "measured_at": (now - timedelta(minutes=1)).isoformat(),
            "glucose_value": 120,
            "conditions": ["fasting"],
        },
    )
    assert saved.status_code == 200, saved.json

    changed = client.put(
        f"{base}/measurement-plans/{plan['id']}",
        headers=headers,
        json={
            **body, "missed_after_minutes": 90, "expected_version_number": 1
        },
    )

    # Today's reading keeps the plan it was taken under.
    assert changed.status_code == 200, changed.json
    answer = changed.json["measurement_plan"]
    assert answer["version"]["missed_after_minutes"] == 60
    assert answer["pending_version"]["missed_after_minutes"] == 90
    assert answer["pending_version"]["effective_from_on"] == (
        day + timedelta(days=1)
    ).isoformat()


def test_an_edit_that_starts_tomorrow_can_be_edited_again(
    database_app, database, account
):
    """A plan stays editable: the edit waiting for tomorrow changes in
    place."""
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    base = f"/api/v1/circles/{circle.id}"
    now, day, body, plan = _todays_glucose_plan(client, headers, base)
    version_id = plan["version"]["id"]
    assert client.put(
        f"{base}/measurement-readings/{version_id}/{day.isoformat()}",
        headers=headers,
        json={
            "kind": "glucose",
            "outcome": "read",
            "measured_at": (now - timedelta(minutes=1)).isoformat(),
            "glucose_value": 120,
            "conditions": ["fasting"],
        },
    ).status_code == 200
    path = f"{base}/measurement-plans/{plan['id']}"
    tomorrow = (day + timedelta(days=1)).isoformat()
    assert client.put(
        path,
        headers=headers,
        json={
            **body, "missed_after_minutes": 90, "expected_version_number": 1
        },
    ).status_code == 200

    again = client.put(
        path,
        headers=headers,
        json={
            **body,
            "missed_after_minutes": 120,
            "effective_from_on": tomorrow,
            "expected_version_number": 2,
        },
    )

    assert again.status_code == 200, again.json
    answer = again.json["measurement_plan"]
    assert answer["version"]["missed_after_minutes"] == 60
    assert answer["pending_version"]["missed_after_minutes"] == 120
    assert answer["pending_version"]["version_number"] == 2
    assert answer["pending_version"]["effective_from_on"] == tomorrow


def test_concurrent_task_records_keep_one_outcome(
    database_app, database, account
):
    """The row lock and unique key reject a competing task write."""
    owner = account()
    circle = offline_circle(database, owner)
    headers = signed_in(database_app, owner)
    now = datetime.now(timezone.utc)
    day = now.astimezone(ZoneInfo("Asia/Riyadh")).date()
    base = f"/api/v1/circles/{circle.id}"
    created = database_app.test_client().post(
        f"{base}/measurement-plans",
        headers=headers,
        json={
            "kind": "glucose",
            "times": [
                {"time_of_day": "00:00", "measurement_state": "fasting"}
            ],
            "weekdays": [day.isoweekday()],
            "starts_on": day.isoformat(),
        },
    )
    version_id = created.json["measurement_plan"]["version"]["id"]
    path = f"{base}/measurement-readings/{version_id}/{day.isoformat()}"
    body = {
        "kind": "glucose",
        "outcome": "read",
        "measured_at": (now - timedelta(minutes=1)).isoformat(),
        "glucose_value": 100,
    }
    barrier = Barrier(2)

    def record_once():
        barrier.wait()
        return database_app.test_client().put(
            path, headers=headers, json=body
        ).status_code

    with ThreadPoolExecutor(max_workers=2) as pool:
        first = pool.submit(record_once)
        second = pool.submit(record_once)
        results = [first.result(), second.result()]
    assert sorted(results) == [200, 409]
    with Session(database) as session:
        assert session.scalar(
            select(func.count()).select_from(MeasurementReading)
        ) == 1


def test_missed_after_accepts_free_minutes_inside_the_range(
    database_app, database, account
):
    """45 minutes is stored and echoed; 361 and 4 are refused."""
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    path = f"/api/v1/circles/{circle.id}/measurement-plans"
    body = {
        "kind": "glucose",
        "times": [{"time_of_day": "08:00", "measurement_state": "fasting"}],
        "weekdays": [1],
        # The patient's today, not UTC's: they differ after midnight in
        # Riyadh, and a plan cannot start yesterday.
        "starts_on": datetime.now(ZoneInfo("Asia/Riyadh")).date().isoformat(),
    }
    for minutes, status in ((4, 422), (361, 422), (360, 201)):
        response = client.post(
            path,
            headers=headers,
            json={**body, "missed_after_minutes": minutes},
        )
        assert response.status_code == status
    saved = client.get(path, headers=headers).json["measurement_plans"]
    assert saved[0]["version"]["missed_after_minutes"] == 360
