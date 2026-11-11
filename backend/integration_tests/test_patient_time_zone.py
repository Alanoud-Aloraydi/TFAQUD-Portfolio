"""Each patient's IANA zone on PostgreSQL: saved, returned, used by the
day rules whoever records, and backfilled by migration 0030."""

from datetime import datetime, timezone
from pathlib import Path

import pytest
from flask_migrate import downgrade, upgrade
from sqlalchemy import inspect, select, text
from sqlalchemy.orm import Session

from app.clock import ManualClock
from app.database import db
from app.models import CareCircle
from integration_tests.helpers import BIRTH, Api, add_manager, count
from integration_tests.helpers import error_code, run

DIRECTORY = str(Path(__file__).resolve().parents[1] / "migrations")
SELF = {"name": "My care", "birth_date": "1954-06-05", "city": "لندن"}


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


def zone_of(engine, circle_id):
    with Session(engine) as session:
        return session.scalar(
            select(CareCircle.time_zone).where(
                CareCircle.id == circle_id
            )
        )


def test_the_zone_sent_is_saved_and_returned(database_app, database, account):
    api = Api(database_app, account())

    created = api.post(
        "/api/v1/circles/self", {**SELF, "time_zone": "Europe/London"}
    )

    assert created.status_code == 201, created.get_json()
    circle = created.json["circle"]
    assert circle["patient"]["time_zone"] == "Europe/London"
    home = api.get("/api/v1/home").json["care_circles"]
    assert [item["time_zone"] for item in home] == ["Europe/London"]


def test_an_app_older_than_zones_gets_the_default(
    database_app, database, account
):
    api = Api(database_app, account())

    created = api.post("/api/v1/circles/self", {**SELF, "city": "الرياض"})

    assert created.json["circle"]["patient"]["time_zone"] == "Asia/Riyadh"


@pytest.mark.parametrize("zone", ["UTC+3", "Mars/Olympus", "../../etc"])
def test_an_unknown_zone_creates_nothing(
    database_app, database, account, zone
):
    api = Api(database_app, account())

    response = api.post("/api/v1/circles/self", {**SELF, "time_zone": zone})

    assert error_code(response, 422) == "invalid_time_zone"
    assert count(database, CareCircle) == 0


def test_an_edit_keeps_the_zone_unless_it_sends_one(
    database_app, database, account
):
    owner = account()
    api = Api(database_app, owner)
    circle_id = api.post(
        "/api/v1/circles/self", {**SELF, "time_zone": "Europe/London"}
    ).json["circle"]["id"]
    url = f"/api/v1/circles/{circle_id}/patient"
    body = {"birth_date": "1954-06-05", "city": "مانشستر"}

    assert api.put(url, body).status_code == 200
    assert zone_of(database, circle_id) == "Europe/London"
    moved = api.put(url, {**body, "time_zone": "America/Toronto"})
    assert moved.json["circle"]["patient"]["time_zone"] == "America/Toronto"
    refused = api.put(url, {**body, "time_zone": "Toronto"})
    assert error_code(refused, 422) == "invalid_time_zone"
    assert zone_of(database, circle_id) == "America/Toronto"


def test_a_member_elsewhere_follows_the_patients_day(
    database_app, database, account, monkeypatch
):
    """21 Oct 12:00 UTC is 22 Oct 01:00 in Auckland and still the 21st in
    Riyadh, where the helping member lives: a visit at 00:30 on the 22nd
    has passed for the patient, and one at 02:00 is still to come."""
    monkeypatch.setitem(
        database_app.extensions,
        "clock",
        ManualClock(datetime(2026, 10, 21, 12, tzinfo=timezone.utc)),
    )
    owner, member = account(), account(name="Sara")
    circle = run(
        database, "create_without_account", owner.id, "Nora", "Family",
        BIRTH, "أوكلاند", time_zone="Pacific/Auckland",
    )
    add_manager(database, owner, circle, member)
    api = Api(database_app, member)
    base = f"/api/v1/circles/{circle.id}/appointments"

    def visit(time_of_day):
        return {
            "specialty": "السكري",
            "kind": "follow_up",
            "other_text": None,
            "scheduled_on": "2026-10-22",
            "time_of_day": time_of_day,
            "place": "الحبيب",
            "remote_method": None,
            "companion_account_ids": [str(member.id)],
        }

    passed = api.post(base, visit("00:30"))
    to_come = api.post(base, visit("02:00"))

    assert error_code(passed, 422) == "appointment_time_in_past"
    assert to_come.status_code == 201, to_come.get_json()


def test_migration_0030_backfills_riyadh_and_keeps_other_zones(
    database_app, database, account
):
    """Patients made before 0030 lived by Riyadh time; a downgrade that
    would move a patient elsewhere to Riyadh is refused.

    Flask-Migrate turns the migration's RuntimeError into exit status 1, as
    `flask db downgrade` would; its log goes to stderr, so the test checks
    that nothing changed: the column and the London zone are still there."""
    owner = account()
    circle = run(database, "create_self", owner.id, "Care", BIRTH, "الرياض")
    db.session.remove()
    downgrade(directory=DIRECTORY, revision="0029")
    try:
        columns = {c["name"] for c in inspect(database).get_columns("patient")}
        assert "time_zone" not in columns
    finally:
        upgrade(directory=DIRECTORY)
    assert zone_of(database, circle.id) == "Asia/Riyadh"

    with database.begin() as connection:
        connection.execute(text(
            "UPDATE care_circle SET time_zone = 'Europe/London'"
        ))
    with pytest.raises(SystemExit):
        downgrade(directory=DIRECTORY, revision="0029")
    try:
        columns = {
            c["name"] for c in inspect(database).get_columns("care_circle")
        }
        assert "time_zone" in columns
        assert zone_of(database, circle.id) == "Europe/London"
    finally:
        upgrade(directory=DIRECTORY)
