"""Changing how a visit went from «السجل», on PostgreSQL: «حضرت», «ملغى»
and «فائت» for a visit whose time came, «قادم» again for a cancelled one
still ahead, and «حضرت» kept while its visit paper has something in it."""

from datetime import datetime, timezone

import pytest

from app.clock import ManualClock
from app.database import db
from integration_tests.helpers import Api, error_code, offline_circle

BASE = "/api/v1/circles/{}/appointments"


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


@pytest.fixture
def morning(database_app, monkeypatch):
    """9 November 2026, 08:00 in Riyadh."""
    clock = ManualClock(datetime(2026, 11, 9, 5, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    return clock


@pytest.fixture
def care(database_app, database, account):
    """Lina's circle for Nora, and her calls to it."""
    owner = account(name="لينا")
    circle = offline_circle(database, owner)
    return Api(database_app, owner), BASE.format(circle.id)


def book(api, base, day, time_of_day="10:00"):
    """A follow-up at «الحبيب» on `day` at `time_of_day`."""
    answer = api.post(base, {
        "specialty": None,
        "kind": "follow_up",
        "other_text": None,
        "scheduled_on": day,
        "time_of_day": time_of_day,
        "place": "الحبيب",
        "remote_method": None,
        "companion_account_ids": [],
    })
    assert answer.status_code == 201, answer.get_json()
    return answer.get_json()["appointment"]


def change(api, base, visit, status):
    """Choose `status` for `visit` as the app last read it."""
    return api.post(
        f"{base}/{visit['id']}/outcome",
        {"status": status, "expected_updated_at": visit["updated_at"]},
    )


def test_a_past_visit_moves_between_attended_cancelled_and_missed(
    care, morning
):
    api, base = care
    visit = book(api, base, "2026-11-09", "09:00")
    # 10:00: its time came an hour ago.
    morning.advance(hours=2)

    for status in ("missed", "completed", "cancelled", "missed"):
        answer = change(api, base, visit, status)
        assert answer.status_code == 200, answer.get_json()
        visit = answer.get_json()["appointment"]
        # «فائت» keeps it open, marked missed.
        assert (visit["status"], visit["marked_missed"]) == (
            ("scheduled", True) if status == "missed" else (status, False)
        )
    listed = api.get(base).get_json()["appointments"][0]
    assert (listed["status"], listed["marked_missed"]) == ("scheduled", True)
    assert listed["visit_filled"] is False


def test_a_cancelled_visit_still_ahead_comes_back_and_nothing_else(
    care, morning
):
    api, base = care
    visit = book(api, base, "2026-11-12")

    # «قادم» cannot be changed from «السجل».
    assert error_code(
        change(api, base, visit, "cancelled"), 422
    ) == "appointment_outcome_closed"
    cancelled = api.post(
        f"{base}/{visit['id']}/status",
        {"status": "cancelled", "expected_updated_at": visit["updated_at"]},
    ).get_json()["appointment"]
    # Before its time it is neither attended nor missed.
    for status in ("completed", "missed"):
        assert error_code(
            change(api, base, cancelled, status), 422
        ) == "appointment_outcome_closed"

    back = change(api, base, cancelled, "scheduled")

    assert back.status_code == 200, back.get_json()
    assert back.get_json()["appointment"]["status"] == "scheduled"


def test_attended_stays_while_its_visit_paper_has_something(care, morning):
    api, base = care
    visit = book(api, base, "2026-11-09", "09:00")
    morning.advance(hours=2)
    visit = change(api, base, visit, "completed").get_json()["appointment"]
    paper = f"{base}/{visit['id']}/visit"
    written = api.put(paper, {"summary": "تحسّن السكر"})
    assert written.status_code == 200, written.get_json()
    listed = api.get(base).get_json()["appointments"][0]
    assert listed["visit_filled"] is True

    refused = change(api, base, listed, "missed")

    assert error_code(refused, 409) == "appointment_visit_filled"
    # Emptied, the paper lets it go, and leaves with it.
    api.put(paper, {"summary": None})
    listed = api.get(base).get_json()["appointments"][0]
    assert listed["visit_filled"] is False
    cancelled = change(api, base, listed, "cancelled")
    assert cancelled.status_code == 200, cancelled.get_json()
    assert api.get(paper).get_json() == {"visit": None}


def test_an_old_read_is_refused(care, morning):
    api, base = care
    visit = book(api, base, "2026-11-09", "09:00")
    morning.advance(hours=2)
    change(api, base, visit, "missed")

    stale = change(api, base, visit, "completed")

    assert error_code(stale, 409) == "appointment_changed"


def test_a_visit_marked_missed_and_then_attended_is_open_no_more(
    care, morning
):
    """«حضرت» from «اليوم» for a visit marked missed clears the mark."""
    api, base = care
    visit = book(api, base, "2026-11-09", "09:00")
    morning.advance(hours=2)
    missed = change(api, base, visit, "missed").get_json()["appointment"]

    attended = api.post(
        f"{base}/{missed['id']}/status",
        {"status": "completed", "expected_updated_at": missed["updated_at"]},
    )

    assert attended.status_code == 200, attended.get_json()
    value = attended.get_json()["appointment"]
    assert (value["status"], value["marked_missed"]) == ("completed", False)
