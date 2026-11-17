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
from integration_tests.test_circle_api import simplified_circle


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


def test_the_companions_say_whether_the_patient_has_a_phone(
    database_app, database, account, circle
):
    # Without a phone, a visit nobody goes with reminds the leader; the
    # form says so.
    owner, care = circle
    member = account(name="سارة")
    add_manager(database, owner, care, member)
    path = f"/api/v1/circles/{care.id}/appointments/companions"

    listed = Api(database_app, owner).get(path).get_json()

    assert listed["patient_has_account"] is False
    assert [person["name"] for person in listed["companions"]] == [
        "سارة", "لينا",
    ]


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


def test_attended_from_an_hour_before_its_time_not_earlier(
    database_app, circle, evening
):
    # 01:09 in Riyadh: «حضرت» shows on «اليوم» an hour before a visit.
    owner, care = circle
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{care.id}/appointments"
    soon = api.post(
        base, visit(owner, scheduled_on="2026-11-09", time_of_day="02:00")
    ).get_json()["appointment"]
    later = api.post(
        base, visit(owner, scheduled_on="2026-11-09", time_of_day="03:30")
    ).get_json()["appointment"]

    attended = api.post(
        f"{base}/{soon['id']}/status",
        {"status": "completed", "expected_updated_at": soon["updated_at"]},
    )
    too_early = api.post(
        f"{base}/{later['id']}/status",
        {"status": "completed", "expected_updated_at": later["updated_at"]},
    )

    assert attended.status_code == 200, attended.get_json()
    assert attended.get_json()["appointment"]["status"] == "completed"
    assert error_code(too_early, 422) == "appointment_not_started"


def test_attended_until_it_leaves_the_attention_list_then_missed(
    database_app, circle, evening
):
    # A visit can be marked attended two patient days after its own, as
    # long as «يحتاج انتباهك» lists it; the day after, it is missed.
    owner, care = circle
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{care.id}/appointments"
    first = api.post(
        base, visit(owner, scheduled_on="2026-11-09", time_of_day="10:00")
    ).get_json()["appointment"]
    second = api.post(
        base, visit(owner, scheduled_on="2026-11-10", time_of_day="10:00")
    ).get_json()["appointment"]
    # 12 November, 01:09 in Riyadh: 9 November is three days back.
    evening.advance(days=3)

    missed = api.post(
        f"{base}/{first['id']}/status",
        {"status": "completed", "expected_updated_at": first["updated_at"]},
    )
    attended = api.post(
        f"{base}/{second['id']}/status",
        {"status": "completed", "expected_updated_at": second["updated_at"]},
    )

    assert error_code(missed, 422) == "appointment_missed"
    assert attended.status_code == 200, attended.get_json()


def test_a_simplified_patient_says_attended_but_cannot_cancel(
    database_app, database, account, evening
):
    # «حضرت» is the patient's own answer in the simplified mode too;
    # cancelling a visit stays with those who manage the appointments.
    owner, patient = account(name="لينا"), account("simplified")
    care = simplified_circle(database, owner, patient)
    base = f"/api/v1/circles/{care.id}/appointments"
    soon = Api(database_app, owner).post(
        base, visit(owner, scheduled_on="2026-11-09", time_of_day="02:00")
    ).get_json()["appointment"]
    as_patient = Api(database_app, patient)
    stamp = {"expected_updated_at": soon["updated_at"]}

    cancelled = as_patient.post(
        f"{base}/{soon['id']}/status", {"status": "cancelled", **stamp}
    )
    attended = as_patient.post(
        f"{base}/{soon['id']}/status", {"status": "completed", **stamp}
    )

    assert error_code(cancelled, 403) == "forbidden"
    assert attended.status_code == 200, attended.get_json()
    assert attended.get_json()["appointment"]["status"] == "completed"
    assert attended.get_json()["appointment"]["updated_by"][
        "account_id"
    ] == str(patient.id)


def test_a_booking_of_several_dates_saves_one_visit_each(
    database_app, circle, evening
):
    """The clinic's sheet: dates that follow no rule, each its own visit,
    tied by one series and listed oldest first."""
    owner, care = circle
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{care.id}/appointments"

    created = api.post(
        base,
        visit(
            owner,
            scheduled_on="2026-12-05",
            also_on=["2027-03-14", "2027-01-09"],
        ),
    )

    assert created.status_code == 201, created.get_json()
    saved = created.get_json()["appointments"]
    assert [item["scheduled_on"] for item in saved] == [
        "2026-12-05",
        "2027-01-09",
        "2027-03-14",
    ]
    series = {item["series_id"] for item in saved}
    assert len(series) == 1 and series != {None}
    # The first is answered as before, for a client that knows one visit.
    assert created.get_json()["appointment"] == saved[0]


def test_a_visit_on_its_own_has_no_series(database_app, circle, evening):
    """Nothing changes for a single appointment."""
    owner, care = circle
    api = Api(database_app, owner)

    created = api.post(f"/api/v1/circles/{care.id}/appointments", visit(owner))

    assert created.status_code == 201, created.get_json()
    assert created.get_json()["appointment"]["series_id"] is None


def test_one_date_already_passed_refuses_the_whole_booking(
    database_app, circle, evening
):
    """All the visits or none: a sheet half saved is worse than none."""
    owner, care = circle
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{care.id}/appointments"

    refused = api.post(
        base, visit(owner, also_on=["2020-01-01", "2027-01-09"])
    )

    assert refused.status_code == 422, refused.get_json()
    listed = api.get(base).get_json()["appointments"]
    assert listed == []


def test_editing_one_visit_leaves_the_rest_of_its_series(
    database_app, circle, evening
):
    """The rule of a series: an edit or a cancellation is that visit only."""
    owner, care = circle
    api = Api(database_app, owner)
    base = f"/api/v1/circles/{care.id}/appointments"
    saved = api.post(
        base, visit(owner, scheduled_on="2026-12-05", also_on=["2027-01-09"])
    ).get_json()["appointments"]
    first, second = saved

    changed = api.put(
        f"{base}/{first['id']}",
        visit(
            owner,
            scheduled_on="2026-12-06",
            place="مستشفى آخر",
            expected_updated_at=first["updated_at"],
        ),
    )

    assert changed.status_code == 200, changed.get_json()
    listed = {
        item["id"]: item for item in api.get(base).get_json()["appointments"]
    }
    assert listed[first["id"]]["place"] == "مستشفى آخر"
    assert listed[second["id"]]["place"] == second["place"]
    assert listed[second["id"]]["scheduled_on"] == "2027-01-09"
    assert listed[first["id"]]["series_id"] == second["series_id"]
