"""The doses of a range of days, worked out from the plans."""

from datetime import date
from uuid import UUID

from sqlalchemy import select

from app.accounts import accounts_by_id
from app.clock import patient_zone
from app.medications.occurrence_builder import build_occurrences
from app.medications.schedule_loading import load_days
from app.models import (
    MedicationPlan,
    MedicationPlanVersion,
    MedicationSchedule,
)
from app.snoozes.queries import attach_snoozes


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
        # the doses themselves (occurrence_builder.py).
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
