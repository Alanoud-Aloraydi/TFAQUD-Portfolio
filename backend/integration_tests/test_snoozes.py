"""«ذكّرني لاحقًا» on PostgreSQL, shared by the circle: every member sees
who put a task off and until when, and at that time every other member is
reminded once."""

from datetime import datetime, timezone

import pytest

from app.clock import ManualClock
from app.database import db
from app.push import RecordingPushSender
from app.snoozes.due import send_due_snoozes
from integration_tests.helpers import add_manager, error_code
from integration_tests.helpers import offline_circle
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
    """08:05 in Riyadh on 28 October 2026, and what would reach Apple."""
    clock = ManualClock(datetime(2026, 10, 28, 5, 5, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    sender = RecordingPushSender()
    monkeypatch.setitem(database_app.extensions, "push_sender", sender)
    return clock, sender


@pytest.fixture
def care(database_app, database, account, morning):
    """Reem's circle with Khaled as a second manager, each signed in on a
    phone, and Metformin due at 08:00."""
    clock, _ = morning
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    add_manager(database, reem, circle, khaled)
    reem_phone = Phone(database_app, reem, "a")
    khaled_phone = Phone(database_app, khaled, "b")
    reem_phone.register()
    khaled_phone.register()
    plan = create_plan(
        database_app.test_client(),
        circle,
        reem_phone.headers,
        plan_body(clock.now()),
    ).json["medication_plan"]
    schedule_id = plan["version"]["schedules"][0]["id"]
    return circle, reem_phone, khaled_phone, schedule_id


def snooze_dose(phone, circle, schedule_id, minutes=15):
    return phone.call(
        "put",
        f"/api/v1/circles/{circle.id}/task-snoozes",
        {
            "task": "dose",
            "task_id": schedule_id,
            "scheduled_on": DAY,
            "minutes": minutes,
        },
    )


def todays_dose(phone, circle):
    response = phone.client.get(
        f"/api/v1/circles/{circle.id}/medication-occurrences",
        headers=phone.headers,
        query_string={"from": DAY, "to": DAY},
    )
    assert response.status_code == 200, response.json
    [dose] = response.json["medication_occurrences"]
    return dose


def test_every_member_sees_who_put_a_dose_off_and_until_when(
    care, morning
):
    circle, reem, khaled, schedule_id = care

    answer = snooze_dose(reem, circle, schedule_id)

    assert answer.status_code == 200, answer.json
    snooze = answer.json["snooze"]
    assert snooze["minutes"] == 15
    assert snooze["remind_at"] == "2026-10-28T05:20:00+00:00"
    assert snooze["snoozed_by"]["name"] == "Reem"
    # Khaled's card says the same.
    assert todays_dose(khaled, circle)["snooze"] == snooze


def test_at_the_new_time_every_other_member_is_reminded_once(
    care, morning
):
    clock, pushes = morning
    circle, reem, khaled, schedule_id = care
    snooze_dose(reem, circle, schedule_id)

    # Before its time, nobody.
    send_due_snoozes(clock.now())
    assert pushes.sent == []

    clock.advance(minutes=15)
    send_due_snoozes(clock.now())
    # Reem's own phone reminds her by itself; Khaled gets the push.
    assert pushes.to(reem.token) == []
    [message] = pushes.to(khaled.token)
    assert message.kind == "dose_snoozed"
    assert message.title == "حان موعد الجرعة المؤجّلة"
    assert message.body == (
        "جرعة Metformin تأجّلت 15 دقيقة من Reem، وحان وقتها. "
        "تقدر تسجّلها من تفقّد."
    )
    # And the card is back to normal.
    assert todays_dose(khaled, circle)["snooze"] is None

    send_due_snoozes(clock.now())
    assert len(pushes.to(khaled.token)) == 1


def test_put_off_again_it_moves_and_reminds_once(care, morning):
    clock, pushes = morning
    circle, reem, khaled, schedule_id = care
    snooze_dose(reem, circle, schedule_id)
    clock.advance(minutes=10)

    again = snooze_dose(khaled, circle, schedule_id, minutes=30)

    assert again.json["snooze"]["snoozed_by"]["name"] == "Khaled"
    clock.advance(minutes=10)
    send_due_snoozes(clock.now())
    assert pushes.sent == []
    clock.advance(minutes=20)
    send_due_snoozes(clock.now())
    assert pushes.to(khaled.token) == []
    assert len(pushes.to(reem.token)) == 1


def test_a_dose_recorded_meanwhile_reminds_nobody(care, morning):
    clock, pushes = morning
    circle, reem, khaled, schedule_id = care
    snooze_dose(reem, circle, schedule_id)
    recorded = khaled.call(
        "put",
        f"/api/v1/circles/{circle.id}/medication-dose-records/"
        f"{schedule_id}/{DAY}",
        {
            "outcome": "taken",
            "taken_at": clock.now().isoformat(),
            "skip_reason_code": None,
            "skip_reason_note": None,
        },
    )
    assert recorded.status_code == 200, recorded.json

    clock.advance(minutes=15)
    send_due_snoozes(clock.now())

    assert pushes.sent == []
    assert todays_dose(reem, circle)["snooze"] is None
    # And it cannot be put off any more.
    assert error_code(
        snooze_dose(reem, circle, schedule_id), 409
    ) == "task_already_recorded"


def test_a_dose_the_circle_does_not_have_cannot_be_put_off(care, morning):
    circle, reem, _, _ = care

    answer = snooze_dose(
        reem, circle, "00000000-0000-0000-0000-000000000000"
    )

    assert answer.status_code == 404


@pytest.mark.parametrize("minutes", [0, 241])
def test_the_minutes_are_from_1_to_240(care, morning, minutes):
    circle, reem, _, schedule_id = care

    answer = snooze_dose(reem, circle, schedule_id, minutes=minutes)

    assert error_code(answer, 422) == "validation_error"


def test_a_reading_time_is_put_off_by_its_time(
    database_app, care, morning
):
    clock, pushes = morning
    circle, reem, khaled, _ = care
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
            "glucose_low": 80,
            "glucose_high": 140,
        },
    )
    assert created.status_code == 201, created.json
    version_id = created.json["measurement_plan"]["version"]["id"]
    base = f"/api/v1/circles/{circle.id}/task-snoozes"
    reading = {
        "task": "measurement",
        "task_id": version_id,
        "scheduled_on": DAY,
        "minutes": 30,
    }

    assert error_code(reem.call("put", base, reading), 422) == (
        "validation_error"
    )
    answer = reem.call("put", base, {**reading, "time_of_day": "08:00"})

    assert answer.status_code == 200, answer.json
    listed = khaled.client.get(
        f"/api/v1/circles/{circle.id}/measurement-occurrences",
        headers=khaled.headers,
        query_string={"from": DAY, "to": DAY},
    ).json["measurement_occurrences"]
    assert listed[0]["snooze"]["snoozed_by"]["name"] == "Reem"
    clock.advance(minutes=30)
    send_due_snoozes(clock.now())
    [message] = pushes.to(khaled.token)
    assert message.kind == "measurement_snoozed"
    assert message.body == (
        "قياس سكر الدم تأجّل 30 دقيقة من Reem، وحان وقته. "
        "تقدر تسجّله من تفقّد."
    )


def test_a_dose_put_off_is_not_called_missed_while_it_waits(
    database_app, care, morning, monkeypatch
):
    clock, pushes = morning
    circle, reem, khaled, schedule_id = care
    monkeypatch.setitem(database_app.config, "TICK_SECRET", "secret")

    def tick():
        response = database_app.test_client().post(
            "/internal/tick", headers={"X-Tick-Secret": "secret"}
        )
        assert response.status_code == 204

    # 09:00: the end of the dose's 60 minutes of grace; put off for an
    # hour.
    clock.advance(minutes=55)
    snooze_dose(khaled, circle, schedule_id, minutes=60)
    clock.advance(minutes=10)
    tick()
    assert pushes.sent == []

    # Its new time: Reem is reminded, and it is not missed yet.
    clock.advance(minutes=50)
    tick()
    assert [m.kind for m in pushes.to(reem.token)] == ["dose_snoozed"]
    # Its grace again after the new time, with nothing recorded: missed.
    clock.advance(minutes=61)
    tick()
    assert [m.kind for m in pushes.to(reem.token)] == [
        "dose_snoozed",
        "dose_missed",
    ]
