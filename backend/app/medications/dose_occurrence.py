"""The dose a record answers: it must be due that day, and a repeat must
be the same."""

from datetime import date
from uuid import UUID

from sqlalchemy import select

from app.clock import local_moment, patient_zone
from app.errors import NotFound
from app.medications.inputs import DoseRecordRequest
from app.medications.schedule_loading import load_days
from app.models import (
    CareCircle,
    MedicationPlan,
    MedicationPlanVersion,
    MedicationSchedule,
)


class DoseOccurrence:
    """Finds the occurrence a record answers."""

    def _require_occurrence(
        self,
        patient: CareCircle,
        schedule_id: UUID,
        scheduled_on: date,
    ) -> None:
        """404 unless the schedule belongs to the circle's patient and has a
        dose on that day.
        """
        row = self.session.execute(
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
                MedicationSchedule.id == schedule_id,
                MedicationPlanVersion.treatment_starts_on <= scheduled_on,
                MedicationPlanVersion.cancelled_at.is_(None),
                (
                    MedicationPlanVersion.treatment_ends_on.is_(None)
                    | (
                        MedicationPlanVersion.treatment_ends_on
                        >= scheduled_on
                    )
                ),
            )
            .with_for_update(of=MedicationPlan)
        ).first()
        if row is None:
            raise NotFound("The scheduled dose does not exist.")
        plan, version, schedule = row
        # A weekly schedule on its weekday, a monthly one on its day of the
        # month, an interval one every few days from the treatment's start.
        if not load_days(self.session, [schedule])[schedule.id].applies_on(
            scheduled_on, version.treatment_starts_on
        ):
            raise NotFound("The scheduled dose does not exist.")
        if version.effective_from_on > scheduled_on:
            raise NotFound("The scheduled dose does not exist.")
        if (
            version.effective_until_on is not None
            and version.effective_until_on <= scheduled_on
        ):
            raise NotFound("The scheduled dose does not exist.")
        if (
            plan.stopped_at is not None
            and local_moment(
                scheduled_on, schedule.time_of_day, patient_zone(patient)
            ) >= plan.stopped_at
        ):
            raise NotFound("The scheduled dose does not exist.")

    @staticmethod
    def _same(record, body: DoseRecordRequest) -> bool:
        """Whether `body` says the same as the saved record."""
        return (
            record.outcome == body.outcome
            and record.taken_at == body.taken_at
            and record.skip_reason_code == body.skip_reason_code
            and record.skip_reason_note == body.skip_reason_note
        )
