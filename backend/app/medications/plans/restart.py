"""Starting a medicine again when its only version had not begun."""

from uuid import UUID

from sqlalchemy import func, select

from app.errors import ValidationFailed
from app.medications.availability import require_available_name
from app.medications.inputs import RevisePlanRequest
from app.medications.plan_versions import add_plan_version
from app.models import MedicationPlan, MedicationPlanVersion


class PlanRestart:
    """Starts a medicine again."""

    def _start_again(
        self,
        plan: MedicationPlan,
        actor_id: UUID,
        body: RevisePlanRequest,
        normalized_name: str,
        today,
    ) -> MedicationPlan:
        """A medicine that has not started yet, edited: its new version
        starts when the treatment does, as a new medicine would."""
        # Like adding the medicine again: not in the past, and no other
        # medicine of that name on the same days.
        if body.treatment_starts_on < today:
            raise ValidationFailed(code="medication_start_in_past")
        require_available_name(
            self.session,
            self._patient_of(plan),
            normalized_name,
            body,
            exclude_plan_id=plan.id,
            effective_from_on=body.treatment_starts_on,
        )
        # The next version number counts every version, cancelled ones too.
        next_number = self.session.scalar(
            select(func.max(MedicationPlanVersion.version_number)).where(
                MedicationPlanVersion.medication_plan_id == plan.id
            )
        ) + 1
        add_plan_version(
            self.session,
            plan,
            actor_id,
            body,
            next_number,
            normalized_name,
            body.treatment_starts_on,
        )
        return plan
