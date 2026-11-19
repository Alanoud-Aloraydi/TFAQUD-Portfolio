"""A medicine without dose times, and «سجّل جرعة الآن» against PostgreSQL."""

from datetime import datetime, timedelta

from integration_tests.helpers import offline_circle
from integration_tests.test_medications import (
    PATIENT_ZONE,
    create_plan,
    plan_body,
    signed_in,
)


def setup_plan(database_app, database, account, **changes):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    now = datetime.now(PATIENT_ZONE)
    created = create_plan(
        client, circle, headers, plan_body(now, **changes)
    )
    assert created.status_code == 201, created.json
    plan = created.json["medication_plan"]
    return client, headers, circle, plan, now


def record(client, headers, circle, **body):
    return client.post(
        f"/api/v1/circles/{circle.id}/medication-extra-doses",
        headers=headers,
        json=body,
    )


def test_a_medicine_can_have_no_dose_time(database_app, database, account):
    _, _, _, plan, _ = setup_plan(
        database_app, database, account, schedules=[]
    )

    assert plan["version"]["schedules"] == []


def test_an_extra_dose_is_recorded_and_listed(
    database_app, database, account
):
    client, headers, circle, plan, now = setup_plan(
        database_app, database, account, schedules=[]
    )
    taken = (now - timedelta(minutes=5)).isoformat()

    added = record(
        client,
        headers,
        circle,
        plan_id=plan["id"],
        taken_at=taken,
        dose_value="1.5",
        dose_unit="tablet",
    )

    assert added.status_code == 201, added.json
    dose = added.json["medication_extra_dose"]
    assert (dose["plan_id"], dose["dose_value"]) == (plan["id"], "1.5")
    day = now.date().isoformat()
    listed = client.get(
        f"/api/v1/circles/{circle.id}/medication-extra-doses"
        f"?from={day}&to={day}",
        headers=headers,
    )
    assert listed.json["medication_extra_doses"] == [dose]


def test_an_extra_dose_never_answers_a_scheduled_one(
    database_app, database, account
):
    client, headers, circle, plan, now = setup_plan(
        database_app, database, account
    )

    added = record(
        client,
        headers,
        circle,
        plan_id=plan["id"],
        taken_at=now.isoformat(),
        dose_value="1",
        dose_unit="tablet",
    )

    assert added.status_code == 201
    day = now.date().isoformat()
    occurrences = client.get(
        f"/api/v1/circles/{circle.id}/medication-occurrences"
        f"?from={day}&to={day}",
        headers=headers,
    ).json["medication_occurrences"]
    assert all(item.get("record") is None for item in occurrences)


def test_a_wrong_extra_dose_is_refused(database_app, database, account):
    client, headers, circle, plan, now = setup_plan(
        database_app, database, account, schedules=[]
    )
    later = (now + timedelta(hours=1)).isoformat()

    future = record(
        client,
        headers,
        circle,
        plan_id=plan["id"],
        taken_at=later,
        dose_value="1",
        dose_unit="tablet",
    )
    wrong_unit = record(
        client,
        headers,
        circle,
        plan_id=plan["id"],
        taken_at=now.isoformat(),
        dose_value="1",
        dose_unit="mL",
    )

    assert future.json["error"]["code"] == "future_taken_time"
    assert wrong_unit.json["error"]["code"] == "dose_unit_mismatch"
