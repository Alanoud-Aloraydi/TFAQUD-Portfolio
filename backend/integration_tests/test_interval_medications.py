"""«نذكرك كل … يوم» on PostgreSQL: a dose every few days from the day the
treatment starts, listed, expanded into doses, and recorded only on its
days."""

from datetime import date, datetime, timezone
from uuid import UUID

import pytest
from sqlalchemy import update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.clock import ManualClock
from app.models import (
    MedicationDoseRecord,
    MedicationSchedule,
    MedicationScheduleDay,
)
from integration_tests.helpers import offline_circle
from integration_tests.test_medications import (
    create_plan,
    plan_body,
    signed_in,
)
from integration_tests.test_monthly_medications import occurrences


@pytest.fixture
def november(database_app, monkeypatch):
    """28 October 2026, 12:00 in Riyadh."""
    clock = ManualClock(datetime(2026, 10, 28, 9, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    return clock


def interval_body(clock, days, **changes):
    body = plan_body(clock.now(), **changes)
    body["schedules"][0].update(
        {"repeat": "interval", "weekdays": [], "interval_days": days}
    )
    return body


@pytest.fixture
def owner_api(database_app, database, account):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    return client, circle, headers


def test_every_three_days_from_the_start(owner_api, november):
    client, circle, headers = owner_api

    created = create_plan(client, circle, headers, interval_body(november, 3))

    assert created.status_code == 201, created.json
    [stored] = created.json["medication_plan"]["version"]["schedules"]
    assert stored["repeat"] == "interval"
    assert stored["interval_days"] == 3
    assert stored["weekdays"] == []
    assert stored["month_days"] == []
    assert occurrences(
        client, circle, headers, "2026-10-27", "2026-11-06"
    ) == ["2026-10-28", "2026-10-31", "2026-11-03", "2026-11-06"]


@pytest.mark.parametrize(
    "change",
    [
        {"interval_days": 0},
        {"interval_days": 91},
        {"interval_days": None},
        {"weekdays": [1]},
        {"repeat": "weekly"},
    ],
)
def test_an_interval_dose_has_its_number_only(owner_api, november, change):
    client, circle, headers = owner_api
    body = interval_body(november, 3)
    body["schedules"][0].update(change)

    assert create_plan(client, circle, headers, body).status_code == 422


def test_two_doses_every_few_days_at_one_time_are_refused(
    owner_api, november
):
    client, circle, headers = owner_api
    body = interval_body(november, 2)
    body["schedules"].append({**body["schedules"][0], "interval_days": 5})

    assert create_plan(client, circle, headers, body).status_code == 422
    body["schedules"][1]["time_of_day"] = "20:00"
    assert create_plan(client, circle, headers, body).status_code == 201


def test_an_interval_dose_is_recorded_only_on_its_days(owner_api, november):
    client, circle, headers = owner_api
    created = create_plan(client, circle, headers, interval_body(november, 2))
    schedule_id = created.json["medication_plan"]["version"]["schedules"][
        0
    ]["id"]
    base = f"/api/v1/circles/{circle.id}/medication-dose-records/{schedule_id}"
    # Three days on: every 2 days from the 28th is the 30th, not the 29th.
    november.advance(days=3)

    assert client.put(
        f"{base}/2026-10-30",
        headers=headers,
        json={"outcome": "taken", "taken_at": "2026-10-30T05:05:00Z"},
    ).status_code == 200
    assert client.put(
        f"{base}/2026-10-29",
        headers=headers,
        json={"outcome": "taken", "taken_at": "2026-10-29T05:05:00Z"},
    ).status_code == 404


def test_the_same_interval_plan_again_is_the_same_version(
    owner_api, november
):
    client, circle, headers = owner_api
    body = interval_body(november, 4)
    plan = create_plan(client, circle, headers, body).json["medication_plan"]
    path = f"/api/v1/circles/{circle.id}/medication-plans/{plan['id']}"

    unchanged = client.put(
        path, headers=headers, json={**body, "expected_version_number": 1}
    )
    assert unchanged.status_code == 200, unchanged.json
    assert unchanged.json["medication_plan"]["version"]["version_number"] == 1

    # Every 5 days is a change, on a new version.
    changed = client.put(
        path,
        headers=headers,
        json={**interval_body(november, 5), "expected_version_number": 1},
    )
    assert changed.status_code == 200, changed.json
    [schedule] = changed.json["medication_plan"]["version"]["schedules"]
    assert schedule["interval_days"] == 5


def test_the_database_keeps_interval_days_whole(
    database, owner_api, november
):
    """The database's own rules, below the API: an interval schedule has a
    number and no weekdays, and a dose is recorded only on its days."""
    client, circle, headers = owner_api
    created = create_plan(client, circle, headers, interval_body(november, 3))
    schedule_id = UUID(
        created.json["medication_plan"]["version"]["schedules"][0]["id"]
    )

    with Session(database) as session:
        session.add(MedicationScheduleDay(schedule_id=schedule_id, weekday=1))
        with pytest.raises(IntegrityError, match="interval schedule"):
            session.commit()

    with Session(database) as session:
        with pytest.raises(IntegrityError, match="interval_days"):
            session.execute(
                update(MedicationSchedule)
                .where(MedicationSchedule.id == schedule_id)
                .values(interval_days=None)
            )

    def record(day):
        with Session(database) as session:
            session.add(
                MedicationDoseRecord(
                    schedule_id=schedule_id,
                    scheduled_on=day,
                    outcome="skipped",
                    skip_reason_code="other",
                    skip_reason_note="test",
                )
            )
            session.commit()

    with pytest.raises(IntegrityError, match="does not belong"):
        record(date(2026, 10, 30))
    record(date(2026, 10, 31))
