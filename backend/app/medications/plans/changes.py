"""Cancelling a coming edit, and stopping a medicine."""

from uuid import UUID

from sqlalchemy import select

from app.clock import patient_today
from app.errors import Conflict
from app.models import MedicationPlan, MedicationPlanVersion


class PlanChanges:
    """Cancels edits and stops medicines."""

    def cancel_pending(
        self,
        circle_id: UUID,
        plan_id: UUID,
        expected_version_number: int,
    ) -> MedicationPlan:
        """Cancel a future revision while retaining its audit version."""
        # Only a medicine in use, whose version read by the app is the one
        # waiting to start.
        plan = self._plan(circle_id, plan_id)
        if plan.stopped_at is not None:
            raise Conflict(code="medication_stopped")
        pending = self._current_version(plan.id)
        today = patient_today(self._patient_of(plan), self.now)
        if (pending.version_number != expected_version_number
                or pending.effective_from_on <= today):
            raise Conflict(code="medication_version_conflict")
        # Cancel it (it stays, for the history), and the version before goes on
        # with no end.
        previous = self.session.scalar(
            select(MedicationPlanVersion).where(
                MedicationPlanVersion.medication_plan_id == plan.id,
                MedicationPlanVersion.effective_until_on
                == pending.effective_from_on,
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        )
        if previous is None:
            raise Conflict(code="medication_version_conflict")
        pending.cancelled_at = self.now
        self.session.flush()
        previous.effective_until_on = None
        self.session.flush()
        return plan

    def stop(
        self,
        circle_id: UUID,
        plan_id: UUID,
        actor_id: UUID,
    ) -> MedicationPlan:
        """Stop a medicine now, and say who stopped it; a medicine already
        stopped stays as it is.
        """
        plan = self._plan(circle_id, plan_id)
        if plan.stopped_at is not None:
            return plan
        plan.stopped_at = self.now
        plan.stopped_by_account_id = actor_id
        self.session.flush()
        return plan
