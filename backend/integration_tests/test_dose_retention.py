"""Doses are kept three months, then deleted for good, against PostgreSQL."""

from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.medications.retention import DOSES_KEPT_DAYS
from app.models import (
    MedicationDoseRecord,
    MedicationExtraDose,
    MedicationPlanVersion,
)
from app.push.scheduled import purge_old_rows
from integration_tests.test_extra_doses import record, setup_plan

# Past the limit whatever the patient's day is in UTC, and on the weekday
# of the weekly dose time (whole weeks back).
GONE = (DOSES_KEPT_DAYS // 7 + 2) * 7


def start_long_ago(database, plan):
    """The medicine started 200 days ago, so its doses reach past three
    months."""
    start = datetime.now(timezone.utc).date() - timedelta(days=200)
    version = MedicationPlanVersion
    with Session(database) as session, session.begin():
        session.execute(
            update(version)
            .where(version.medication_plan_id == UUID(plan["id"]))
            .values(treatment_starts_on=start, effective_from_on=start)
        )


def test_doses_past_three_months_are_deleted(
    database_app, database, account
):
    _, _, _, plan, now = setup_plan(database_app, database, account)
    start_long_ago(database, plan)
    schedule_id = UUID(plan["version"]["schedules"][0]["id"])
    stamp = datetime.now(timezone.utc)
    with Session(database) as session, session.begin():
        for days in (GONE, 0):
            session.add(
                MedicationDoseRecord(
                    schedule_id=schedule_id,
                    scheduled_on=now.date() - timedelta(days=days),
                    outcome="skipped",
                    recorded_at=stamp,
                )
            )
            session.add(
                MedicationExtraDose(
                    medication_plan_id=UUID(plan["id"]),
                    taken_at=stamp - timedelta(days=days),
                    dose_value=1,
                    dose_unit="tablet",
                    recorded_at=stamp,
                )
            )

    with database_app.app_context():
        purge_old_rows(datetime.now(timezone.utc))

    with Session(database) as session:
        days = list(session.scalars(select(MedicationDoseRecord.scheduled_on)))
        extra = list(session.scalars(select(MedicationExtraDose.taken_at)))
    assert days == [now.date()]
    assert extra == [stamp]


def test_the_days_past_three_months_are_not_answered(
    database_app, database, account
):
    client, headers, circle, plan, now = setup_plan(
        database_app, database, account
    )
    start_long_ago(database, plan)

    def doses(first, last):
        return client.get(
            f"/api/v1/circles/{circle.id}/medication-occurrences"
            f"?from={(now - timedelta(days=first)).date().isoformat()}"
            f"&to={(now - timedelta(days=last)).date().isoformat()}",
            headers=headers,
        ).json["medication_occurrences"]

    assert doses(GONE + 28, GONE) == []
    assert len(doses(28, 1)) == 4


def test_a_dose_past_three_months_is_refused(
    database_app, database, account
):
    client, headers, circle, plan, now = setup_plan(
        database_app, database, account
    )
    start_long_ago(database, plan)
    schedule_id = plan["version"]["schedules"][0]["id"]
    day = (now - timedelta(days=GONE)).date().isoformat()

    scheduled = client.put(
        f"/api/v1/circles/{circle.id}/medication-dose-records/"
        f"{schedule_id}/{day}",
        headers=headers,
        json={"outcome": "skipped", "skip_reason_code": "forgotten"},
    )
    extra = record(
        client,
        headers,
        circle,
        plan_id=plan["id"],
        taken_at=(now - timedelta(days=GONE)).isoformat(),
        dose_value="1",
        dose_unit="tablet",
    )

    assert scheduled.json["error"]["code"] == "dose_too_old"
    assert extra.json["error"]["code"] == "dose_too_old"
