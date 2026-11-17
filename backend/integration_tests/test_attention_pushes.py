"""«يحتاج انتباهك» told at once, on PostgreSQL through the real endpoints:
a skipped dose, a reading outside its range, a cancelled visit reach the
circle's other members and the patient, but not the one who did it, and
not a patient in the simplified mode."""

from datetime import datetime, timezone

import pytest

from app.clock import ManualClock
from app.database import db
from app.push import RecordingPushSender
from integration_tests.helpers import BIRTH, add_manager, offline_circle, run
from integration_tests.test_appointments import visit
from integration_tests.test_circle_api import simplified_circle
from integration_tests.test_medications import create_plan, plan_body
from integration_tests.test_push_api import Phone

DAY = "2026-10-28"


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


@pytest.fixture
def morning(database_app, monkeypatch):
    """08:05 in Riyadh on 28 October 2026, and what would reach a phone."""
    clock = ManualClock(datetime(2026, 10, 28, 5, 5, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    sender = RecordingPushSender()
    monkeypatch.setitem(database_app.extensions, "push_sender", sender)
    return clock, sender


def dose_of(database_app, circle, phone, clock, name="Metformin"):
    """A medicine due at 08:00 today; its schedule's id."""
    plan = create_plan(
        database_app.test_client(), circle, phone.headers,
        plan_body(clock.now(), name=name),
    ).json["medication_plan"]
    return plan["version"]["schedules"][0]["id"]


def skip(phone, circle, schedule_id, **reason):
    return phone.call(
        "put",
        f"/api/v1/circles/{circle.id}/medication-dose-records/"
        f"{schedule_id}/{DAY}",
        {"outcome": "skipped", **reason},
    )


@pytest.fixture
def family(database_app, database, account, morning):
    """Nora's circle (no phone of her own), led by Reem, with Khaled."""
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    add_manager(database, reem, circle, khaled)
    return circle, Phone(database_app, reem), Phone(database_app, khaled)


def test_a_skipped_dose_tells_the_others_why_once(
    database_app, family, morning
):
    clock, pushes = morning
    circle, reem, khaled = family
    schedule_id = dose_of(database_app, circle, reem, clock, "بتراترا")

    answer = skip(reem, circle, schedule_id, skip_reason_code="forgotten")
    again = skip(reem, circle, schedule_id, skip_reason_code="forgotten")

    assert answer.status_code == 200, answer.json
    assert again.status_code == 200, again.json
    assert pushes.to(reem.token) == []
    [message] = pushes.to(khaled.token)
    assert message.kind == "dose_skipped"
    assert message.title == "جرعة تم تخطيها"
    assert message.body == (
        "يا Khaled، دواء Nora البتراترا تم تخطيه بسبب نسيان Nora لأخذه"
    )
    assert dict(message.target)["schedule_id"] == schedule_id


def test_a_taken_dose_tells_nobody(database_app, family, morning):
    clock, pushes = morning
    circle, reem, _ = family
    schedule_id = dose_of(database_app, circle, reem, clock)

    answer = reem.call(
        "put",
        f"/api/v1/circles/{circle.id}/medication-dose-records/"
        f"{schedule_id}/{DAY}",
        {"outcome": "taken", "taken_at": "2026-10-28T05:01:00+00:00"},
    )

    assert answer.status_code == 200, answer.json
    assert pushes.sent == []


def glucose(value):
    return {
        "kind": "glucose",
        "outcome": "read",
        "measured_at": "2026-10-28T05:00:00+00:00",
        "glucose_value": value,
        "conditions": ["fasting"],
    }


def test_a_reading_outside_its_range_needs_the_others_attention(
    family, morning
):
    _, pushes = morning
    circle, reem, khaled = family
    base = f"/api/v1/circles/{circle.id}/measurement-readings"

    normal = khaled.call("post", base, glucose(90))
    high = khaled.call("post", base, glucose(250))

    assert normal.status_code == 201, normal.json
    assert high.status_code == 201, high.json
    assert pushes.to(khaled.token) == []
    [message] = pushes.to(reem.token)
    assert message.kind == "measurement_unusual"
    assert message.body == "يا Reem، قياس السكر لـNora يحتاج انتباهك!"


def test_a_planned_reading_points_at_its_time(family, morning):
    _, pushes = morning
    circle, reem, khaled = family
    created = reem.call(
        "post",
        f"/api/v1/circles/{circle.id}/measurement-plans",
        {
            "kind": "glucose",
            "times": [
                {"time_of_day": "08:00", "measurement_state": "fasting"}
            ],
            "weekdays": [3],
            "starts_on": DAY,
            "missed_after_minutes": 60,
        },
    )
    version_id = created.json["measurement_plan"]["version"]["id"]

    answer = reem.call(
        "put",
        f"/api/v1/circles/{circle.id}/measurement-readings/"
        f"{version_id}/{DAY}?time=08:00",
        glucose(40),
    )

    assert answer.status_code == 200, answer.json
    [message] = pushes.to(khaled.token)
    assert dict(message.target) == {
        "circle_id": str(circle.id),
        "plan_version_id": version_id,
        "scheduled_on": DAY,
        "time_of_day": "08:00",
    }


def test_a_cancelled_visit_names_it(family, morning):
    _, pushes = morning
    circle, reem, khaled = family
    base = f"/api/v1/circles/{circle.id}/appointments"
    created = reem.call(
        "post", base,
        {**visit(reem.account, kind="therapy_session"),
         "companion_account_ids": []},
    ).json["appointment"]

    answer = reem.call(
        "post",
        f"{base}/{created['id']}/status",
        {"status": "cancelled", "expected_updated_at": created["updated_at"]},
    )

    assert answer.status_code == 200, answer.json
    assert pushes.to(reem.token) == []
    [message] = pushes.to(khaled.token)
    assert message.kind == "appointment_cancelled"
    assert message.body == "يا Khaled، موعد Nora لجلسة علاج تم إلغاؤه"


def test_a_patient_in_the_simplified_mode_is_not_told(
    database_app, database, account, morning
):
    clock, pushes = morning
    reem, sami = account(name="Reem"), account(mode="simplified", name="Sami")
    khaled = account(name="Khaled")
    circle = simplified_circle(database, reem, sami)
    add_manager(database, reem, circle, khaled)
    reem_phone = Phone(database_app, reem)
    sami_phone = Phone(database_app, sami)
    khaled_phone = Phone(database_app, khaled)
    schedule_id = dose_of(database_app, circle, reem_phone, clock)

    skip(reem_phone, circle, schedule_id, skip_reason_code="side_effects")

    assert pushes.to(sami_phone.token) == []
    [message] = pushes.to(khaled_phone.token)
    assert message.body == (
        "يا Khaled، دواء Sami Metformin تم تخطيه بسبب ظهور أعراض جانبية"
    )


def test_a_patient_in_the_full_app_hears_of_their_own(
    database_app, database, account, morning
):
    clock, pushes = morning
    nora, khaled = account(name="Nora"), account(name="Khaled")
    circle = run(database, "create_self", nora.id, "My care", BIRTH, "Riyadh")
    add_manager(database, nora, circle, khaled)
    nora_phone, khaled_phone = Phone(database_app, nora), Phone(
        database_app, khaled
    )
    schedule_id = dose_of(database_app, circle, nora_phone, clock)

    skip(khaled_phone, circle, schedule_id, skip_reason_code="unavailable")

    assert pushes.to(khaled_phone.token) == []
    [message] = pushes.to(nora_phone.token)
    assert message.body == (
        "يا Nora، دواؤك Metformin تم تخطيه بسبب عدم توفر الدواء لك"
    )
