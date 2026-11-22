"""The reminders of a visit, sent by the server, on PostgreSQL: a day
before it and at its lead, only to those who go, and once right after a
visit saved too late for the one a day before."""

from datetime import datetime, timezone

import pytest

from app.clock import ManualClock
from app.database import db
from app.push import RecordingPushSender
from app.push.scheduled import run_tick
from integration_tests.helpers import Api, add_manager, offline_circle
from integration_tests.test_push_api import Phone
from integration_tests.test_server_reminders import at, move_to


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


def visit(api, circle, day, time_of_day, companions=()):
    """A follow-up at the diabetes clinic in «الحبيب»."""
    created = api.post(
        f"/api/v1/circles/{circle.id}/appointments",
        {
            "specialty": "السكري",
            "kind": "follow_up",
            "other_text": None,
            "scheduled_on": day,
            "time_of_day": time_of_day,
            "place": "الحبيب",
            "remote_method": None,
            "companion_account_ids": [str(one.id) for one in companions],
        },
    )
    assert created.status_code == 201, created.get_json()
    return created.get_json()["appointment"]


def test_a_visit_reminds_those_going_a_day_before_and_an_hour_before(
    database_app, database, account, early
):
    clock, pushes = early
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    add_manager(database, reem, circle, khaled)
    reem_phone = Phone(database_app, reem).subscribe(server_reminders=True)
    khaled_phone = Phone(database_app, khaled).subscribe(
        server_reminders=True
    )
    saved = visit(
        Api(database_app, reem), circle, "2026-10-29", "10:00", [khaled]
    )

    # 10:00 on the 28th: a day before.
    at(clock, 10)
    run_tick(clock.now())
    [message] = pushes.to(khaled_phone.token)
    assert message.kind == "appointment_reminder"
    assert message.title == "يا Khaled، لا ننسى موعد Nora غدًا"
    assert message.body == "مراجعة، السكري، الساعة 10:00 ص، الحبيب"
    assert dict(message.target) == {
        "circle_id": str(circle.id),
        "appointment_id": saved["id"],
        "reminder": f"appointment:{circle.id}@{saved['id']}",
    }
    # Nothing to put off on a visit.
    assert message.category is None
    # Only Khaled goes with Nora.
    assert pushes.to(reem_phone.token) == []

    # 09:00 on the 29th: an hour before, its lead.
    move_to(clock, datetime(2026, 10, 29, 6, tzinfo=timezone.utc))
    run_tick(clock.now())
    assert pushes.to(khaled_phone.token)[-1].title == (
        "يا Khaled، لا ننسى موعد Nora بعد ساعة"
    )
    assert len(pushes.sent) == 2


def test_a_visit_nobody_goes_with_reminds_the_stand_in_leader(
    database_app, database, account, early
):
    """Nora has no phone and nobody goes with her: Reem, who leads her
    circle, is reminded."""
    clock, pushes = early
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    add_manager(database, reem, circle, khaled)
    reem_phone = Phone(database_app, reem).subscribe(server_reminders=True)
    Phone(database_app, khaled).subscribe(server_reminders=True)
    visit(Api(database_app, reem), circle, "2026-10-29", "10:00")

    at(clock, 10)
    run_tick(clock.now())
    [(reminded, _)] = pushes.sent
    assert reminded == reem_phone.token


def test_a_visit_saved_after_its_day_before_moment_is_said_once(
    database_app, database, account, early
):
    """Saved at 07:00 for 18:00 today, it is said half a minute later; and
    a visit at 06:00 tomorrow, saved now too, says «غدًا»."""
    clock, pushes = early
    reem = account(name="Reem")
    circle = offline_circle(database, reem)
    phone = Phone(database_app, reem).subscribe(server_reminders=True)
    api = Api(database_app, reem)
    visit(api, circle, "2026-10-28", "18:00")
    visit(api, circle, "2026-10-29", "06:00")

    clock.advance(seconds=30)
    run_tick(clock.now())
    titles = sorted(message.title for message in pushes.to(phone.token))
    assert titles == [
        "يا Reem، لا ننسى موعد Nora اليوم",
        "يا Reem، لا ننسى موعد Nora غدًا",
    ]

    clock.advance(minutes=1)
    run_tick(clock.now())
    assert len(pushes.sent) == 2
