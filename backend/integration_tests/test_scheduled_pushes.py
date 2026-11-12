"""The scheduled tick on PostgreSQL: it tells only of a missed dose, once.

The reminder at the dose time is set on the phone by the app, so the tick
sends nothing while a dose is due.
"""

from datetime import datetime, timezone

import pytest

from app.clock import ManualClock
from app.push import RecordingPushSender
from integration_tests.helpers import offline_circle
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
    assert message.body == (
        "جرعة Metformin موعدها 8:00 ص فاتت. تقدر تسجّلها من تفقّد."
    )

    # A later tick does not send it again.
    tick(database_app)
    assert len(pushes.to(phone.token)) == 1
