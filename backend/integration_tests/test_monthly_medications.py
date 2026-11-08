"""Monthly medicine schedules on PostgreSQL: stored, listed, expanded into
doses on their days (a missing day on the month's last day), and recorded
only on those days."""

from datetime import date, datetime, timezone
from uuid import UUID

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.clock import ManualClock
from app.models import MedicationDoseRecord, MedicationScheduleDay
from integration_tests.helpers import offline_circle
from integration_tests.test_medications import (
    create_plan,
    plan_body,
    signed_in,
)


@pytest.fixture
def november(database_app, monkeypatch):
    """28 October 2026, 12:00 in Riyadh."""
    clock = ManualClock(datetime(2026, 10, 28, 9, tzinfo=timezone.utc))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    return clock


def monthly_body(clock, month_days, **changes):
    body = plan_body(clock.now(), **changes)
    body["schedules"][0].update(
        {"repeat": "monthly", "weekdays": [], "month_days": month_days}
    )
    return body


def occurrences(client, circle, headers, start, end):
    response = client.get(
        f"/api/v1/circles/{circle.id}/medication-occurrences",
        headers=headers,
        query_string={"from": start, "to": end},
    )
    assert response.status_code == 200, response.json
    return [item["scheduled_on"] for item in response.json[
        "medication_occurrences"
    ]]


def test_a_monthly_plan_is_kept_and_listed(
    database_app, database, account, november
):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)

    created = create_plan(
        client, circle, headers, monthly_body(november, [15, 1])
    )

    assert created.status_code == 201, created.json
    [stored] = created.json["medication_plan"]["version"]["schedules"]
    assert stored["repeat"] == "monthly"
    assert stored["month_days"] == [1, 15]
    assert stored["weekdays"] == []
    assert occurrences(
        client, circle, headers, "2026-11-01", "2026-11-30"
    ) == ["2026-11-01", "2026-11-15"]


def test_a_day_the_month_lacks_is_its_last_day(
    database_app, database, account, november
):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    created = create_plan(
        client, circle, headers, monthly_body(november, [30, 31])
    )
    assert created.status_code == 201, created.json

    # October has the 30th and the 31st; November only the 30th, once.
    assert occurrences(
        client, circle, headers, "2026-10-30", "2026-11-30"
    ) == ["2026-10-30", "2026-10-31", "2026-11-30"]


def test_a_monthly_dose_is_recorded_only_on_its_day(
    database_app, database, account, november
):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    created = create_plan(
        client, circle, headers, monthly_body(november, [28])
    )
    schedule_id = created.json["medication_plan"]["version"]["schedules"][
        0
    ]["id"]
    base = f"/api/v1/circles/{circle.id}/medication-dose-records/{schedule_id}"
    taken = {"outcome": "taken", "taken_at": "2026-10-28T05:05:00Z"}

    assert client.put(
        f"{base}/2026-10-28", headers=headers, json=taken
    ).status_code == 200
    # The same weekday a week earlier is not a day of this schedule.
    assert client.put(
        f"{base}/2026-10-21", headers=headers, json=taken
    ).status_code == 404


def test_the_same_monthly_plan_again_is_the_same_version(
    database_app, database, account, november
):
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    body = monthly_body(november, [5])
    plan = create_plan(client, circle, headers, body).json["medication_plan"]
    path = f"/api/v1/circles/{circle.id}/medication-plans/{plan['id']}"

    unchanged = client.put(
        path, headers=headers, json={**body, "expected_version_number": 1}
    )
    assert unchanged.status_code == 200, unchanged.json
    assert unchanged.json["medication_plan"]["version"]["version_number"] == 1

    # Weekly on the same time is a change.
    weekly = plan_body(november.now(), expected_version_number=1)
    changed = client.put(path, headers=headers, json=weekly)
    assert changed.status_code == 200, changed.json
    [schedule] = changed.json["medication_plan"]["version"]["schedules"]
    assert schedule["repeat"] == "weekly"


def test_the_database_keeps_monthly_days_whole(
    database_app, database, account, november
):
    """The database's own rules, below the API: a monthly schedule has no
    weekdays, and a dose is recorded only on one of its days."""
    owner = account()
    circle = offline_circle(database, owner)
    client = database_app.test_client()
    headers = signed_in(database_app, owner)
    created = create_plan(
        client, circle, headers, monthly_body(november, [31])
    )
    schedule_id = UUID(
        created.json["medication_plan"]["version"]["schedules"][0]["id"]
    )

    with Session(database) as session:
        session.add(MedicationScheduleDay(schedule_id=schedule_id, weekday=1))
        with pytest.raises(IntegrityError, match="day of the month"):
            session.commit()

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
        record(date(2026, 11, 29))
    # November's last day stands for the 31st.
    record(date(2026, 11, 30))
