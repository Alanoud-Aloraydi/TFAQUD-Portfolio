"""The doses of a range of days, worked out from the plans and never
stored: weekly and monthly schedules expanded into calendar days, each
with its record, and the latest record of each plan read at once for a
list."""

from collections import defaultdict
from datetime import date, datetime, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import func, select

from app.accounts import accounts_by_id, recorder_response
from app.clock import local_moment, patient_zone
from app.medications.doses import first_kept_day
from app.medications.schedules import load_days, timing_state, version_applies
from app.medications.views import occurrence_response
from app.models import (
    MedicationDoseRecord,
    MedicationPlan,
    MedicationPlanVersion,
    MedicationSchedule,
)
from app.snoozes.queries import attach_snoozes


def build_occurrences(
    rows,
    days,
    records,
    accounts,
    from_date: date,
    to_date: date,
    now: datetime,
    zone: ZoneInfo,
):
    """Build only applicable occurrences, selecting the latest version.

    `rows` are (plan, version, schedule); `days` maps each schedule's id to
    its `ScheduleDays`. A schedule's time is wall clock in the patient's
    `zone`, so a dose at 08:00 stays at 08:00 there across a DST change.
    """
    # Group the rows by medicine.
    by_plan = defaultdict(list)
    for row in rows:
        by_plan[row[0].id].append(row)
    result = []
    current = from_date
    # Each day, for each medicine, only its latest version in force that day
    # gives doses.
    while current <= to_date:
        for plan_rows in by_plan.values():
            eligible = [
                row
                for row in plan_rows
                if version_applies(row[1], current)
            ]
            if not eligible:
                continue
            version_number = max(row[1].version_number for row in eligible)
            for plan, version, schedule in eligible:
                if version.version_number != version_number or not days[
                    schedule.id
                ].applies_on(current, version.treatment_starts_on):
                    continue
                # A dose after the medicine was stopped is not a dose.
                scheduled_at = local_moment(
                    current, schedule.time_of_day, zone
                )
                if (
                    plan.stopped_at is not None
                    and scheduled_at >= plan.stopped_at
                ):
                    continue
                # The dose, with its record and whether it is to come, due or
                # missed.
                record = records.get((schedule.id, current))
                result.append(
                    occurrence_response(
                        plan,
                        version,
                        schedule,
                        current,
                        record,
                        accounts,
                        timing_state(
                            scheduled_at,
                            now,
                            record,
                            version.missed_after_minutes,
                        ),
                    )
                )
        current += timedelta(days=1)
    return sorted(
        result,
        key=lambda item: (
            item["scheduled_on"],
            item["time_of_day"],
            item["name"],
        ),
    )


class Occurrences:
    """Works out the doses of some days."""

    def occurrences(
        self,
        circle_id: UUID,
        from_date: date,
        to_date: date,
        plan_id: UUID | None = None,
    ) -> list[dict]:
        """The doses due from `from_date` to `to_date`, with their records,
        their timing (to come, due, missed) and who put them off until when
        (`snooze`), optionally for one medicine.
        """
        # The days past three months are deleted (app.medications.doses):
        # none of their doses is answered, so none comes back as missed.
        from_date = max(from_date, first_kept_day(self.now))
        if from_date > to_date:
            return []
        patient = self._patient(circle_id)
        # Every dose time of the patient's versions (not cancelled) whose
        # treatment overlaps the range.
        statement = (
            select(
                MedicationPlan,
                MedicationPlanVersion,
                MedicationSchedule,
            )
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .join(
                MedicationSchedule,
                MedicationSchedule.plan_version_id
                == MedicationPlanVersion.id,
            )
            .where(
                MedicationPlan.care_circle_id == patient.id,
                MedicationPlanVersion.treatment_starts_on <= to_date,
                MedicationPlanVersion.cancelled_at.is_(None),
                (
                    MedicationPlanVersion.treatment_ends_on.is_(None)
                    | (
                        MedicationPlanVersion.treatment_ends_on
                        >= from_date
                    )
                ),
            )
        )
        if plan_id is not None:
            statement = statement.where(MedicationPlan.id == plan_id)
        rows = list(self.session.execute(statement))
        # Their days, their records in the range, and who recorded them; then
        # the doses themselves (above).
        schedule_ids = {row[2].id for row in rows}
        days = load_days(self.session, [row[2] for row in rows])
        records = self._records(schedule_ids, from_date, to_date)
        accounts = accounts_by_id(
            self.session,
            {
                record.recorded_by_account_id
                for record in records.values()
                if record.recorded_by_account_id is not None
            },
        )
        occurrences = build_occurrences(
            rows, days, records, accounts, from_date, to_date, self.now,
            patient_zone(patient),
        )
        return attach_snoozes(
            self.session, circle_id, "dose", occurrences, from_date,
            to_date, self.now,
        )

    # Reads the latest dose of each plan.
    def _latest_records(self, care_circle_id: UUID) -> dict[str, dict]:
        """Find the latest explicit dose outcome for each medication plan."""
        # Number each plan's dose records from the latest (by day, then dose
        # time, then when it was recorded), across all its versions, every
        # record counting (this is history).
        ranked = (
            select(
                MedicationPlan.id.label("plan_id"),
                MedicationDoseRecord.outcome,
                MedicationDoseRecord.scheduled_on,
                MedicationDoseRecord.taken_at,
                MedicationDoseRecord.skip_reason_code,
                MedicationDoseRecord.skip_reason_note,
                MedicationDoseRecord.recorded_by_account_id,
                MedicationSchedule.time_of_day,
                func.row_number().over(
                    partition_by=MedicationPlan.id,
                    order_by=(
                        MedicationDoseRecord.scheduled_on.desc(),
                        MedicationSchedule.time_of_day.desc(),
                        MedicationDoseRecord.recorded_at.desc(),
                    ),
                ).label("position"),
            )
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .join(
                MedicationSchedule,
                MedicationSchedule.plan_version_id
                == MedicationPlanVersion.id,
            )
            .join(
                MedicationDoseRecord,
                MedicationDoseRecord.schedule_id
                == MedicationSchedule.id,
            )
            .where(MedicationPlan.care_circle_id == care_circle_id)
            .subquery()
        )
        # Keep the first of each plan, and who recorded it.
        rows = list(self.session.execute(
            select(ranked).where(ranked.c.position == 1)
        ))
        accounts = accounts_by_id(
            self.session,
            {
                row.recorded_by_account_id
                for row in rows
                if row.recorded_by_account_id is not None
            },
        )
        # As the app reads it, by plan id.
        latest = {}
        for row in rows:
            latest[str(row.plan_id)] = {
                "outcome": row.outcome,
                "scheduled_on": row.scheduled_on.isoformat(),
                "time_of_day": row.time_of_day.isoformat(
                    timespec="minutes"
                ),
                "taken_at": (
                    row.taken_at.isoformat() if row.taken_at else None
                ),
                "skip_reason_code": row.skip_reason_code,
                "skip_reason_note": row.skip_reason_note,
                "recorded_by": recorder_response(
                    accounts.get(row.recorded_by_account_id)
                ),
            }
        return latest
