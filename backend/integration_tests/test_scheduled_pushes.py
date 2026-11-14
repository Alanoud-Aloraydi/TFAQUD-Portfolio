"""The scheduled tick on PostgreSQL: it tells only of a missed dose or
appointment, once, calling each person by name.

The reminder at the dose time is set on the phone by the app, so the tick
sends nothing while a dose is due.
"""

from datetime import datetime, timezone

import pytest

from app.clock import ManualClock
from app.push import RecordingPushSender
from integration_tests.helpers import Api, offline_circle
from integration_tests.test_medications import (
    create_plan,
    plan_body,
    signed_in,
)
from integration_tests.test_push_api import Phone

SECRET = "tick-secret-for-tests"


@pytest.fixture
def ticking(database_app, monkeypatch):
    """A fixed clock at 08:00 in Riyadh, the tick's secret, and the pushes."""
    clock = ManualClock(datetime(2026, 10, 28, 5, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    monkeypatch.setitem(database_app.config, "TICK_SECRET", SECRET)
    sender = RecordingPushSender()
    monkeypatch.setitem(database_app.extensions, "push_sender", sender)
    return clock, sender


def tick(app):
    response = app.test_client().post(
        "/internal/tick", headers={"X-Tick-Secret": SECRET}
    )
    assert response.status_code == 204


def test_only_a_missed_dose_is_told_and_only_once(
    database_app, database, account, ticking
):
    clock, pushes = ticking
    owner = account(name="Reem")
    phone = Phone(database_app, owner, "a")
    phone.register()
    circle = offline_circle(database, owner)
    created = create_plan(
        database_app.test_client(),
        circle,
        signed_in(database_app, owner),
        plan_body(clock.now()),
    )
    assert created.status_code == 201

    # 08:05 in Riyadh: the dose is due, and the phone reminds of it.
    clock.advance(minutes=5)
    tick(database_app)
    assert pushes.to(phone.token) == []

    # 23:00 in Riyadh: the time passed with nothing recorded.
    clock.advance(hours=14, minutes=55)
    tick(database_app)
    [message] = pushes.to(phone.token)
    assert message.kind == "dose_missed"
    assert message.title == "جرعة فائتة"
    # Reem cares for Nora: she hears whose dose it is.
    assert message.body == (
        "يا Reem، جرعة Metformin لـNora فاتت، ليسارع بأخذها"
    )

    # A later tick does not send it again.
    tick(database_app)
    assert len(pushes.to(phone.token)) == 1


def _appointment(api, circle, **changes):
    """A follow-up today, 28 October, at 09:00 in Riyadh."""
    created = api.post(
        f"/api/v1/circles/{circle.id}/appointments",
        {
            "specialty": "السكري",
            "kind": "follow_up",
            "other_text": None,
            "scheduled_on": "2026-10-28",
            "time_of_day": "09:00",
            "place": "الحبيب",
            "remote_method": None,
            "companion_account_ids": [],
            **changes,
        },
    )
    assert created.status_code == 201, created.get_json()
    return created.get_json()["appointment"]


def test_an_appointment_nobody_marked_is_told_two_hours_after_once(
    database_app, database, account, ticking
):
    clock, pushes = ticking
    owner = account(name="Reem")
    phone = Phone(database_app, owner, "a")
    phone.register()
    circle = offline_circle(database, owner)
    _appointment(Api(database_app, owner), circle)

    # 10:55 in Riyadh: not two hours yet.
    clock.advance(hours=2, minutes=55)
    tick(database_app)
    assert pushes.to(phone.token) == []

    # 11:05: two hours passed and nobody marked it visited or cancelled.
    clock.advance(minutes=10)
    tick(database_app)
    [message] = pushes.to(phone.token)
    assert message.kind == "appointment_missed"
    assert message.title == "موعد فائت"
    assert message.body == "يا Reem، موعد Nora فات"

    tick(database_app)
    assert len(pushes.to(phone.token)) == 1


def test_an_appointment_marked_visited_is_not_told(
    database_app, database, account, ticking
):
    clock, pushes = ticking
    owner = account(name="Reem")
    phone = Phone(database_app, owner, "a")
    phone.register()
    circle = offline_circle(database, owner)
    api = Api(database_app, owner)
    saved = _appointment(api, circle)

    # 09:30: the visit happened, and Reem marks it.
    clock.advance(hours=1, minutes=30)
    visited = api.post(
        f"/api/v1/circles/{circle.id}/appointments/{saved['id']}/status",
        {"status": "completed", "expected_updated_at": saved["updated_at"]},
    )
    assert visited.status_code == 200, visited.get_json()

    clock.advance(hours=2)
    tick(database_app)
    assert pushes.to(phone.token) == []
