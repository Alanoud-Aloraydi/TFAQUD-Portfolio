"""Medication endpoints and database rules against PostgreSQL."""

from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from threading import Barrier
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.clock import ManualClock
from app.errors import Conflict
from app.medications.inputs import PlanRequest
from app.medications.plans import MedicationPlanService
from app.models import MedicationDoseRecord, MedicationPlanVersion
from integration_tests.helpers import offline_circle

# The test circle's patient lives in Riyadh (the default zone). A test on
# the real clock reads the day there, as the server does: in UTC it would
# still be yesterday after 21:00 UTC, a start date the server refuses.
PATIENT_ZONE = ZoneInfo("Asia/Riyadh")


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
    now = datetime.now(PATIENT_ZONE)
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
    now = datetime.now(PATIENT_ZONE)
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
    now = datetime.now(PATIENT_ZONE)
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

    listed = client.get(
        f"/api/v1/circles/{circle.id}/medication-plans",
        headers=headers,
    )
    last_record = listed.json["medication_plans"][0]["last_record"]
    assert last_record["outcome"] == "taken"
    assert last_record["scheduled_on"] == now.date().isoformat()
    assert last_record["time_of_day"] == "08:00"

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
    database_app, database, account, monkeypatch
):
    clock = ManualClock(datetime(2026, 10, 28, 9, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    owner = account()
    circle = offline_circle(database, owner)
    now = clock.now()
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    plan = create_plan(client, circle, headers, plan_body(now)).json[
        "medication_plan"
    ]
    path = f"/api/v1/circles/{circle.id}/medication-plans/{plan['id']}"
    # A change chosen for tomorrow waits as the pending version.
    revised_body = plan_body(
        now,
        expected_version_number=1,
        effective_from_on=(now + timedelta(days=1)).date().isoformat(),
    )
    revised_body["strength_value"] = "850"
    revised = client.put(path, headers=headers, json=revised_body)
    assert revised.status_code == 200
    assert revised.json["medication_plan"]["version"]["version_number"] == 1
    assert len(revised.json["medication_plan"]["history"]) == 1
    assert (
        revised.json["medication_plan"]["pending_version"]["version_number"]
        == 2
    )

    stale = client.put(path, headers=headers, json=revised_body)
    assert stale.status_code == 409
    with Session(database) as session:
        versions = session.scalar(
            select(func.count()).select_from(MedicationPlanVersion)
        )
    assert versions == 2

    cancelled = client.post(
        f"{path}/cancel-pending",
        headers=headers,
        json={"expected_version_number": 2},
    )
    assert cancelled.status_code == 200
    assert cancelled.json["medication_plan"]["version"]["version_number"] == 1
    assert "pending_version" not in cancelled.json["medication_plan"]

    replacement = client.put(path, headers=headers, json=revised_body)
    assert replacement.status_code == 200
    assert (
        replacement.json["medication_plan"]["pending_version"]
        ["version_number"] == 3
    )
    clock.advance(days=2)
    current = client.get(
        path, headers=signed_in(database_app, owner)
    )
    assert current.status_code == 200
    assert [
        version["version_number"]
        for version in current.json["medication_plan"]["history"]
    ] == [1, 3]


def test_an_edit_on_the_day_the_medicine_was_added_replaces_it(
    database_app, database, account, monkeypatch
):
    clock = ManualClock(datetime(2026, 10, 28, 9, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    owner = account()
    circle = offline_circle(database, owner)
    now = clock.now()
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    plan = create_plan(client, circle, headers, plan_body(now)).json[
        "medication_plan"
    ]
    path = f"/api/v1/circles/{circle.id}/medication-plans/{plan['id']}"

    fixed = plan_body(now, expected_version_number=1)
    fixed["strength_value"] = "850"
    first = client.put(path, headers=headers, json=fixed)

    assert first.status_code == 200, first.json
    version = first.json["medication_plan"]["version"]
    assert version["strength_value"] == "850"
    assert version["effective_from_on"] == "2026-10-28"
    assert "pending_version" not in first.json["medication_plan"]

    # A second edit the same day replaces it again.
    again = plan_body(
        now, expected_version_number=version["version_number"]
    )
    again["strength_value"] = "1000"
    second = client.put(path, headers=headers, json=again)
    assert second.status_code == 200, second.json
    assert second.json["medication_plan"]["version"]["strength_value"] == (
        "1000"
    )
    # Today's doses follow the newest plan.
    day = now.date().isoformat()
    occurrences = client.get(
        f"/api/v1/circles/{circle.id}/medication-occurrences"
        f"?from={day}&to={day}",
        headers=headers,
    )
    assert occurrences.status_code == 200, occurrences.json
    assert [o["strength_value"] for o in occurrences.json[
        "medication_occurrences"
    ]] == ["1000"]
    # An occurrence says what the medicine is for: the patient's own
    # screen shows that in place of the strength.
    assert [o["reason_for_use"] for o in occurrences.json[
        "medication_occurrences"
    ]] == ["Diabetes"]
    # The replaced versions stay, cancelled, for the audit.
    with Session(database) as session:
        cancelled = session.scalar(
            select(func.count())
            .select_from(MedicationPlanVersion)
            .where(MedicationPlanVersion.cancelled_at.is_not(None))
        )
    assert cancelled == 2


def test_a_same_day_edit_after_a_recorded_dose_starts_tomorrow(
    database_app, database, account, monkeypatch
):
    clock = ManualClock(datetime(2026, 10, 28, 9, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    owner = account()
    circle = offline_circle(database, owner)
    now = clock.now()
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    plan = create_plan(client, circle, headers, plan_body(now)).json[
        "medication_plan"
    ]
    schedule_id = plan["version"]["schedules"][0]["id"]
    taken = client.put(
        f"/api/v1/circles/{circle.id}/medication-dose-records/"
        f"{schedule_id}/{now.date().isoformat()}",
        headers=headers,
        json={
            "outcome": "taken",
            "taken_at": (now - timedelta(minutes=1)).isoformat(),
        },
    )
    assert taken.status_code == 200, taken.json
    path = f"/api/v1/circles/{circle.id}/medication-plans/{plan['id']}"

    changed = plan_body(now, expected_version_number=1)
    changed["strength_value"] = "850"
    revised = client.put(path, headers=headers, json=changed)

    # The dose taken today keeps its plan; the change starts tomorrow.
    assert revised.status_code == 200, revised.json
    answer = revised.json["medication_plan"]
    assert answer["version"]["strength_value"] == "500"
    assert answer["pending_version"]["strength_value"] == "850"
    assert answer["pending_version"]["effective_from_on"] == "2026-10-29"
    with Session(database) as session:
        assert session.scalar(
            select(func.count()).select_from(MedicationDoseRecord)
        ) == 1


def test_an_edit_that_starts_tomorrow_can_be_edited_again(
    database_app, database, account, monkeypatch
):
    """A medicine stays editable: a second edit takes the place of the
    one waiting for tomorrow, which is kept, cancelled, for the audit."""
    clock = ManualClock(datetime(2026, 10, 28, 9, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    owner = account()
    circle = offline_circle(database, owner)
    now = clock.now()
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    plan = create_plan(client, circle, headers, plan_body(now)).json[
        "medication_plan"
    ]
    schedule_id = plan["version"]["schedules"][0]["id"]
    assert client.put(
        f"/api/v1/circles/{circle.id}/medication-dose-records/"
        f"{schedule_id}/{now.date().isoformat()}",
        headers=headers,
        json={
            "outcome": "taken",
            "taken_at": (now - timedelta(minutes=1)).isoformat(),
        },
    ).status_code == 200
    path = f"/api/v1/circles/{circle.id}/medication-plans/{plan['id']}"
    first = plan_body(now, expected_version_number=1, strength_value="850")
    pending = client.put(path, headers=headers, json=first).json[
        "medication_plan"
    ]["pending_version"]
    assert pending["version_number"] == 2

    again = client.put(
        path,
        headers=headers,
        json=plan_body(
            now, expected_version_number=2, strength_value="1000"
        ),
    )

    assert again.status_code == 200, again.json
    answer = again.json["medication_plan"]
    assert answer["version"]["strength_value"] == "500"
    assert answer["pending_version"]["strength_value"] == "1000"
    assert answer["pending_version"]["effective_from_on"] == "2026-10-29"
    with Session(database) as session:
        cancelled = session.scalars(
            select(MedicationPlanVersion.version_number).where(
                MedicationPlanVersion.cancelled_at.is_not(None)
            )
        ).all()
    assert cancelled == [2]


def test_a_medicine_that_starts_later_can_be_edited(
    database_app, database, account, monkeypatch
):
    clock = ManualClock(datetime(2026, 10, 28, 9, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    owner = account()
    circle = offline_circle(database, owner)
    later = clock.now() + timedelta(days=3)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    plan = create_plan(client, circle, headers, plan_body(later)).json[
        "medication_plan"
    ]
    path = f"/api/v1/circles/{circle.id}/medication-plans/{plan['id']}"

    edited = client.put(
        path,
        headers=headers,
        json=plan_body(
            later,
            expected_version_number=1,
            name="Metformin XR",
            treatment_starts_on="2026-11-01",
        ),
    )

    assert edited.status_code == 200, edited.json
    version = edited.json["medication_plan"]["version"]
    assert version["name"] == "Metformin XR"
    assert version["treatment_starts_on"] == "2026-11-01"
    assert version["effective_from_on"] == "2026-11-01"
    assert edited.json["medication_plan"].get("pending_version") is None


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
        f"{plan_path}/stop", headers=headers
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
