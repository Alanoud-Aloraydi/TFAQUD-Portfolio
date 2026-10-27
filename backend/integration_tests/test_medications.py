"""Medication endpoints and database rules against PostgreSQL."""

from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import MedicationDoseRecord, MedicationPlanVersion
from integration_tests.helpers import offline_circle


def signed_in(app, account):
    issued = app.extensions["session_service"].create_session(account.id.hex)
    return {"Authorization": "Bearer " + issued.access_token}


def plan_body(day, **changes):
    value = {
        "name": "Metformin",
        "strength_text": "500 mg",
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
    revised_body["strength_text"] = "850 mg"
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
