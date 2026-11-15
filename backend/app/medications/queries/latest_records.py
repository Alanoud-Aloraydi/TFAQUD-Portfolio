"""The latest dose record of each plan, read at once for a list."""

from uuid import UUID

from sqlalchemy import func, select

from app.accounts import accounts_by_id, recorder_response
from app.models import (
    MedicationDoseRecord,
    MedicationPlan,
    MedicationPlanVersion,
    MedicationSchedule,
)


class LatestRecords:
    """Reads the latest dose of each plan."""

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
