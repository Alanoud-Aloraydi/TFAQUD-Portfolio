"""The reminders at a task's time, sent by the server, on PostgreSQL.

Each comes at its time, once, with the plan as it is then: a dose taken
early, or put off, is not reminded of. It goes only to the phones whose app
asked for the server's reminders; an app from before sets its own.
"""

from datetime import datetime, timedelta, timezone

import pytest

from app.clock import ManualClock
from app.database import db
from app.push import NoPushSender, RecordingPushSender
from app.push.scheduled import run_tick
from app.push.reminders import remind_on_time
from integration_tests.helpers import BIRTH, add_manager, offline_circle, run
from integration_tests.test_medications import create_plan, plan_body
from integration_tests.test_push_api import Phone

DAY = "2026-10-28"


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release the scan's transaction before the next test truncates
    tables."""
    yield
    db.session.remove()


@pytest.fixture
def early(database_app, monkeypatch):
    """07:00 in Riyadh on 28 October 2026, and what would reach OneSignal."""
    clock = ManualClock(datetime(2026, 10, 28, 4, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    sender = RecordingPushSender()
    monkeypatch.setitem(database_app.extensions, "push_sender", sender)
    return clock, sender


@pytest.fixture
def care(database_app, database, account, early):
    """Reem leads Nora's circle and her app asks for the server's
    reminders; Khaled helps, with an app from before. Metformin is due at
    08:00."""
    clock, _ = early
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    add_manager(database, reem, circle, khaled)
    reem_phone = Phone(database_app, reem).subscribe(server_reminders=True)
    khaled_phone = Phone(database_app, khaled).subscribe()
    plan = create_plan(
        database_app.test_client(), circle, reem_phone.headers,
        plan_body(clock.now()),
    ).json["medication_plan"]
    schedule_id = plan["version"]["schedules"][0]["id"]
    return circle, reem_phone, khaled_phone, schedule_id


def move_to(clock, moment):
    """Move the clock forward to `moment`."""
    clock.advance(seconds=(moment - clock.now()).total_seconds())


def at(clock, hour, minute=0):
    """Move the clock to `hour`:`minute` in Riyadh on 28 October."""
    move_to(
        clock, datetime(2026, 10, 28, hour - 3, minute, tzinfo=timezone.utc)
    )


def test_the_app_that_asks_is_told_whether_the_server_reminds_it(care):
    _, reem, khaled, _ = care

    assert reem.answer == {"server_reminders": True}
    # An app from before asks nothing, and keeps setting its own.
    assert khaled.answer == {"server_reminders": False}


def test_a_dose_is_reminded_at_its_time_once_to_the_phone_that_asked(
    database_app, care, early
):
    clock, pushes = early
    circle, reem, khaled, schedule_id = care

    at(clock, 7, 59)
    run_tick(clock.now())
    assert pushes.sent == []

    at(clock, 8)
    run_tick(clock.now())
    [message] = pushes.to(reem.token)
    assert message.kind == "dose_reminder"
    assert message.title == "حان موعد الدواء"
    # The app's own words: Reem cares for Nora.
    assert message.body == "يا Reem، لا ننسى Metformin لـNora"
    # Stacked with the circle's, with «ذكّرني لاحقًا».
    assert message.thread == str(circle.id)
    assert message.category == "tafaqod.reminder"
    target = dict(message.target)
    assert target.pop("reminder").split("\x1f") == [
        f"dose:{circle.id}", message.title, message.body,
        f"{circle.id}|{schedule_id}|2026-10-28", "Metformin",
    ]
    assert target == {
        "circle_id": str(circle.id),
        "schedule_id": schedule_id,
        "scheduled_on": DAY,
    }
    # Khaled's app sets its own reminder.
    assert pushes.to(khaled.token) == []

    at(clock, 8, 1)
    run_tick(clock.now())
    assert len(pushes.sent) == 1


def test_a_dose_taken_early_is_not_reminded_of(care, early):
    clock, pushes = early
    circle, reem, _, schedule_id = care
    at(clock, 7, 40)
    taken = reem.call(
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
    assert taken.status_code == 200, taken.json

    at(clock, 8)
    run_tick(clock.now())
    assert pushes.sent == []


def test_a_reminder_the_server_could_not_send_in_time_is_dropped(
    care, early
):
    """The server was away at 08:00: at 08:06 the reminder is too late,
    and the push of the missed dose comes after its grace instead."""
    clock, pushes = early
    at(clock, 8, 6)
    run_tick(clock.now())
    assert pushes.sent == []


def test_a_signed_out_phone_is_not_reminded(care, early):
    clock, pushes = early
    _, reem, _, _ = care
    reem.sign_out()

    at(clock, 8)
    run_tick(clock.now())
    assert pushes.sent == []


def test_each_moment_before_the_next_scan_gets_a_timer(
    database_app, care, early, monkeypatch
):
    """The minute scan at 07:59:30 sets a timer for 08:00, so the
    reminder comes on its minute, read again then."""
    clock, pushes = early
    circle, reem, _, _ = care
    timers = []
    monkeypatch.setattr(
        "app.push.reminders.run_at",
        lambda when, now, job, *args: timers.append((when, job, args)),
    )
    at(clock, 7, 59)
    clock.advance(seconds=30)

    run_tick(clock.now(), timedelta(seconds=60))
    assert pushes.sent == []
    [(when, job, args)] = timers
    assert when == datetime(2026, 10, 28, 5, tzinfo=timezone.utc)
    assert (job, args) == (remind_on_time, (circle.id,))

    move_to(clock, when)
    job(*args)
    [message] = pushes.to(reem.token)
    assert message.kind == "dose_reminder"


@pytest.mark.parametrize("switch", ["setting", "no_onesignal"])
def test_without_the_server_reminders_every_app_sets_its_own(
    database_app, database, account, early, monkeypatch, switch
):
    clock, pushes = early
    if switch == "setting":
        monkeypatch.setitem(database_app.config, "SERVER_REMINDERS", False)
    else:
        monkeypatch.setitem(
            database_app.extensions, "push_sender", NoPushSender()
        )
    reem = account(name="Reem")
    circle = offline_circle(database, reem)
    phone = Phone(database_app, reem).subscribe(server_reminders=True)
    create_plan(
        database_app.test_client(), circle, phone.headers,
        plan_body(clock.now()),
    )

    assert phone.answer == {"server_reminders": False}
    at(clock, 8)
    run_tick(clock.now())
    assert pushes.sent == []


def test_the_patient_reads_their_own_reminder(
    database_app, database, account, early
):
    clock, pushes = early
    nora = account(name="Nora", mode="detailed")
    circle = run(database, "create_self", nora.id, "Care", BIRTH, "Riyadh")
    phone = Phone(database_app, nora).subscribe(server_reminders=True)
    create_plan(
        database_app.test_client(), circle, phone.headers,
        plan_body(clock.now(), name="ميلبون"),
    )

    at(clock, 8)
    run_tick(clock.now())
    [message] = pushes.to(phone.token)
    assert message.body == "يا Nora، لا ننسى الميلبون"


def test_a_reading_time_is_reminded_with_the_apps_words(
    database_app, care, early
):
    clock, pushes = early
    circle, reem, _, _ = care
    created = reem.call(
        "post",
        f"/api/v1/circles/{circle.id}/measurement-plans",
        {
            "kind": "blood_pressure",
            "times": [
                {"time_of_day": "09:00", "measurement_state": "morning"},
            ],
            "weekdays": [3],
            "starts_on": DAY,
            "missed_after_minutes": 60,
        },
    )
    assert created.status_code == 201, created.json

    at(clock, 9)
    run_tick(clock.now())
    [message] = [
        one for one in pushes.to(reem.token)
        if one.kind == "measurement_reminder"
    ]
    assert (message.title, message.body) == (
        "Reem، حان وقت القياس", "ضغط الدم لـNora"
    )
    payload = dict(message.target)["reminder"].split("\x1f")
    assert payload[0] == f"measurement:{circle.id}"
    assert payload[3].endswith("|09:00|2026-10-28")
    assert payload[4] == "bp"
