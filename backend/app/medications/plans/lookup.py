"""Reading a plan, its patient, its current version and whether it has
doses."""

from uuid import UUID

from sqlalchemy import select

from app.errors import Conflict, NotFound
from app.models import (
    CareCircle,
    MedicationDoseRecord,
    MedicationPlan,
    MedicationPlanVersion,
    MedicationSchedule,
)


class PlanLookup:
    """Reads a plan and what the workflows check."""

    def _patient_of(self, plan: MedicationPlan) -> CareCircle:
        """The plan's patient, already loaded and locked by `_plan`."""
        return self.session.get(CareCircle, plan.care_circle_id)

    def _plan(self, circle_id: UUID, plan_id: UUID) -> MedicationPlan:
        """The patient's medicine with this id, its patient row locked; 404 for
        a medicine of another patient.
        """
        patient = self._patient(circle_id, lock=True)
        plan = self.session.scalar(
            select(MedicationPlan)
            .where(
                MedicationPlan.id == plan_id,
                MedicationPlan.care_circle_id == patient.id,
            )
            .with_for_update()
        )
        if plan is None:
            raise NotFound("The medication plan does not exist.")
        return plan

    def _has_doses(self, version: MedicationPlanVersion) -> bool:
        """Whether any dose was recorded under this version."""
        return self.session.scalar(
            select(MedicationDoseRecord.id)
            .join(
                MedicationSchedule,
                MedicationSchedule.id == MedicationDoseRecord.schedule_id,
            )
            .where(MedicationSchedule.plan_version_id == version.id)
            .limit(1)
        ) is not None

    def _current_version(self, plan_id: UUID) -> MedicationPlanVersion:
        """The version in force: not ended, not cancelled."""
        version = self.session.scalar(
            select(MedicationPlanVersion).where(
                MedicationPlanVersion.medication_plan_id == plan_id,
                MedicationPlanVersion.effective_until_on.is_(None),
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        )
        if version is None:
            raise Conflict(code="medication_has_no_current_version")
        return version
