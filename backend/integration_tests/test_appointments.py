"""Appointments on PostgreSQL through the real endpoints: saved, listed,
edited and closed, with who made and who last changed each one."""

from datetime import datetime, timezone
from pathlib import Path

import pytest
from flask_migrate import downgrade, upgrade

from app.clock import ManualClock
from app.database import db
from integration_tests.helpers import Api, add_manager, error_code
from integration_tests.helpers import offline_circle


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


@pytest.fixture
def evening(database_app, monkeypatch):
    """9 November 2026, 01:09 in Riyadh."""
    clock = ManualClock(datetime(2026, 11, 8, 22, 9, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    return clock


@pytest.fixture
def circle(database, account):
    owner = account(name="لينا")
    return owner, offline_circle(database, owner)


def visit(companion, **changes):
    """A diabetes follow-up at «الحبيب» on Wednesday 11 November, 10:00."""
    return {
        "specialty": "السكري",
        "kind": "follow_up",
        "other_text": None,
        "scheduled_on": "2026-11-11",
        "time_of_day": "10:00",
        "place": "الحبيب",
        "remote_method": None,
        "companion_account_ids": [str(companion.id)],
        **changes,
    }


def test_a_visit_needs_no_clinic_and_any_known_kind(
    database_app, circle, evening
):
    owner, care = circle
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{care.id}/appointments"

    created = api.post(base, visit(owner, specialty=None, kind="vaccine"))
    assert created.status_code == 201, created.get_json()
    saved = created.get_json()["appointment"]
    assert saved["specialty"] is None
    assert saved["kind"] == "vaccine"

    blank = api.post(base, visit(owner, specialty="   "))
    assert blank.status_code == 201, blank.get_json()
    assert blank.get_json()["appointment"]["specialty"] is None

    unknown = api.post(base, visit(owner, kind="cardiology"))
    assert unknown.status_code == 422, unknown.get_json()


def test_an_appointment_is_saved_and_listed(database_app, circle, evening):
    owner, care = circle
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{care.id}/appointments"

    created = api.post(base, visit(owner))

    assert created.status_code == 201, created.get_json()
    saved = created.get_json()["appointment"]
    assert saved["specialty"] == "السكري"
    assert saved["status"] == "scheduled"
    assert saved["created_by"]["name"] == "لينا"
    assert saved["updated_by"] is None
    listed = api.get(base)
    assert listed.status_code == 200, listed.get_json()
    assert [item["id"] for item in listed.get_json()["appointments"]] == [
        saved["id"]
    ]


def test_an_edit_and_a_cancellation_say_who_made_them(
    database_app, database, account, circle, evening
):
    owner, care = circle
    other = account(name="حامد")
    add_manager(database, owner, care, other)
    base = f"/api/v1/circles/{care.id}/appointments"
    saved = Api(database_app, owner).post(base, visit(owner)).get_json()[
        "appointment"
    ]
    editor = Api(database_app, other)

    edited = editor.put(
        f"{base}/{saved['id']}",
        {
            **visit(other, time_of_day="11:30"),
            "expected_updated_at": saved["updated_at"],
        },
    )

    assert edited.status_code == 200, edited.get_json()
    changed = edited.get_json()["appointment"]
    assert changed["time_of_day"] == "11:30"
    assert changed["created_by"]["name"] == "لينا"
    assert changed["updated_by"]["name"] == "حامد"

    cancelled = editor.post(
        f"{base}/{saved['id']}/status",
        {
            "status": "cancelled",
            "expected_updated_at": changed["updated_at"],
        },
    )
    assert cancelled.status_code == 200, cancelled.get_json()
    assert cancelled.get_json()["appointment"]["status"] == "cancelled"
    assert cancelled.get_json()["appointment"]["updated_by"]["name"] == "حامد"


def test_a_time_already_passed_is_refused(database_app, circle, evening):
    owner, care = circle
    api = Api(database_app, owner)

    refused = api.post(
        f"/api/v1/circles/{care.id}/appointments",
        visit(owner, scheduled_on="2026-11-08"),
    )

    assert error_code(refused, 422) == "appointment_time_in_past"


def test_an_appointment_can_have_no_companion(database_app, circle, evening):
    owner, care = circle
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{care.id}/appointments"

    created = api.post(base, {**visit(owner), "companion_account_ids": []})

    assert created.status_code == 201, created.get_json()
    saved = created.get_json()["appointment"]
    assert saved["companions"] == []
    # And an edit can take the last companion off.
    with_one = api.post(
        base, visit(owner, time_of_day="12:00")
    ).get_json()["appointment"]
    edited = api.put(
        f"{base}/{with_one['id']}",
        {
            **visit(owner, time_of_day="12:00"),
            "companion_account_ids": [],
            "expected_updated_at": with_one["updated_at"],
        },
    )
    assert edited.status_code == 200, edited.get_json()
    assert edited.get_json()["appointment"]["companions"] == []


def test_a_companion_from_outside_the_circle_is_still_refused(
    database_app, account, circle, evening
):
    owner, care = circle
    stranger = account(name="غريب")

    refused = Api(database_app, owner).post(
        f"/api/v1/circles/{care.id}/appointments", visit(stranger)
    )

    assert error_code(refused, 422) == "appointment_invalid_companion"


def test_going_back_before_0032_is_refused_while_one_has_no_companion(
    database_app, circle, evening
):
    """Flask-Migrate turns the migration's RuntimeError into exit status 1,
    as `flask db downgrade` would."""
    owner, care = circle
    Api(database_app, owner).post(
        f"/api/v1/circles/{care.id}/appointments",
        {**visit(owner), "companion_account_ids": []},
    )
    db.session.remove()
    directory = str(Path(__file__).resolve().parents[1] / "migrations")

    with pytest.raises(SystemExit):
        downgrade(directory=directory, revision="0031")
    upgrade(directory=directory)
