"""Medication endpoints and database rules against PostgreSQL."""

from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from threading import Barrier

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.clock import ManualClock
from app.errors import Conflict
from app.medications.inputs import PlanRequest
from app.medications.plans import MedicationPlanService
from app.models import MedicationDoseRecord, MedicationPlanVersion
from integration_tests.helpers import offline_circle


def signed_in(app, account):
    issued = app.extensions["session_service"].create_session(account.id.hex)
    return {"Authorization": "Bearer " + issued.access_token}


def plan_body(day, **changes):
    value = {
        "name": "Metformin",
        "strength_value": "500",
        "strength_unit": "mg",
        "dosage_form": "tablet",
        "reason_for_use": "Diabetes",
        "instructions": "With food",
        "treatment_starts_on": day.date().isoformat(),
        "treatment_ends_on": None,
        "schedules": [
            {
                "time_of_day": "08:00",
                "dose_value": 1,
                "dose_unit": "tablet",
                "weekdays": [day.isoweekday()],
                "instructions": None,
            }
        ],
    }
    value.update(changes)
    return value


def create_plan(client, circle, headers, body):
    return client.post(
        f"/api/v1/circles/{circle.id}/medication-plans",
        headers=headers,
        json=body,
    )


def test_manager_creates_and_lists_a_complete_plan(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    now = datetime.now(timezone.utc)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)

    created = create_plan(client, circle, headers, plan_body(now))
    assert created.status_code == 201
    assert created.json["medication_plan"]["version"]["schedules"]

    listed = client.get(
        f"/api/v1/circles/{circle.id}/medication-plans",
        headers=headers,
    )
    schedules = listed.json["medication_plans"][0]["version"]["schedules"]
    assert schedules[0]["weekdays"] == [now.isoweekday()]


def test_overlapping_current_name_is_rejected_but_later_period_is_allowed(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    now = datetime.now(timezone.utc)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    first = plan_body(
        now,
        treatment_ends_on=(now + timedelta(days=7)).date().isoformat(),
    )
    assert create_plan(client, circle, headers, first).status_code == 201

    conflict = create_plan(client, circle, headers, plan_body(now))
    assert conflict.status_code == 409
    assert conflict.json["error"]["code"] == "medication_period_conflict"

    later = now + timedelta(days=8)
    assert create_plan(
        client, circle, headers, plan_body(later)
    ).status_code == 201


def test_recording_a_dose_is_idempotent_and_conflicting_change_is_rejected(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    now = datetime.now(timezone.utc)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    plan = create_plan(client, circle, headers, plan_body(now)).json[
        "medication_plan"
    ]
    schedule_id = plan["version"]["schedules"][0]["id"]
    path = (
        f"/api/v1/circles/{circle.id}/medication-dose-records/"
        f"{schedule_id}/{now.date().isoformat()}"
    )
    body = {
        "outcome": "taken",
        "taken_at": (now - timedelta(minutes=1)).isoformat(),
        "skip_reason_code": None,
        "skip_reason_note": None,
    }
    first = client.put(path, headers=headers, json=body)
    second = client.put(path, headers=headers, json=body)
    assert first.status_code == second.status_code == 200
    assert first.json == second.json

    conflict = client.put(
        path,
        headers=headers,
        json={"outcome": "skipped"},
    )
    assert conflict.status_code == 409
    with Session(database) as session:
        count = session.scalar(
            select(func.count()).select_from(MedicationDoseRecord)
        )
    assert count == 1


def test_revision_keeps_history_and_requires_the_expected_version(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    now = datetime.now(timezone.utc)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    plan = create_plan(client, circle, headers, plan_body(now)).json[
        "medication_plan"
    ]
    path = f"/api/v1/circles/{circle.id}/medication-plans/{plan['id']}"
    revised_body = plan_body(now, expected_version_number=1)
    revised_body["strength_value"] = "850"
    revised = client.put(path, headers=headers, json=revised_body)
    assert revised.status_code == 200
    assert revised.json["medication_plan"]["version"]["version_number"] == 2

    stale = client.put(path, headers=headers, json=revised_body)
    assert stale.status_code == 409
    with Session(database) as session:
        versions = session.scalar(
            select(func.count()).select_from(MedicationPlanVersion)
        )
    assert versions == 2


def test_future_revision_and_immediate_stop_keep_only_earlier_dose(
    database_app, database, account, monkeypatch
):
    now = datetime(2026, 10, 28, 9, tzinfo=timezone.utc)
    monkeypatch.setitem(database_app.extensions, "clock", ManualClock(now))
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    body = plan_body(now)
    body["schedules"] = [
        {**body["schedules"][0], "time_of_day": value}
        for value in ("08:00", "16:00")
    ]
    plan = create_plan(client, circle, headers, body).json[
        "medication_plan"
    ]
    morning = plan["version"]["schedules"][0]
    dose_path = (
        f"/api/v1/circles/{circle.id}/medication-dose-records/"
        f"{morning['id']}/{now.date().isoformat()}"
    )
    recorded = client.put(
        dose_path,
        headers=headers,
        json={
            "outcome": "taken",
            "taken_at": "2026-10-28T05:05:00Z",
        },
    )
    assert recorded.status_code == 200

    plan_path = (
        f"/api/v1/circles/{circle.id}/medication-plans/{plan['id']}"
    )
    revision = {
        **body,
        "strength_value": "850",
        "expected_version_number": 1,
        "effective_from_on": "2026-10-29",
    }
    revised = client.put(plan_path, headers=headers, json=revision)
    assert revised.status_code == 200
    assert client.post(
        f"{plan_path}/discontinue", headers=headers
    ).status_code == 200

    listed = client.get(
        f"/api/v1/circles/{circle.id}/medication-occurrences",
        headers=headers,
        query_string={"from": "2026-10-28", "to": "2026-10-28"},
    )
    occurrences = listed.json["medication_occurrences"]
    assert [item["time_of_day"] for item in occurrences] == ["08:00"]
    assert occurrences[0]["record"]["outcome"] == "taken"


def test_parallel_creation_keeps_one_overlapping_name(
    database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    now = datetime(2026, 10, 28, 9, tzinfo=timezone.utc)
    body = PlanRequest.model_validate(plan_body(now))
    barrier = Barrier(2)

    def create():
        barrier.wait(timeout=10)
        try:
            with Session(database) as session:
                with session.begin():
                    MedicationPlanService(session, now).create(
                        circle.id, owner.id, body
                    )
            return "created"
        except Conflict:
            return "conflict"

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: create(), range(2)))
    assert sorted(results) == ["conflict", "created"]
