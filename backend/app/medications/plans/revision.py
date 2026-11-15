"""Editing a medicine: a new version from the day it starts."""

from uuid import UUID

from app.clock import patient_today
from app.errors import Conflict, ValidationFailed
from app.medications.availability import require_available_name
from app.medications.inputs import RevisePlanRequest
from app.medications.plans.names import normalize_medication_name
from app.medications.same_definition import same_definition
from app.models import MedicationPlan


class PlanRevision:
    """Edits a medicine."""

    def revise(
        self,
        circle_id: UUID,
        plan_id: UUID,
        actor_id: UUID,
        body: RevisePlanRequest,
    ) -> MedicationPlan:
        """Edit a medicine. A version that starts later is replaced. Otherwise
        the edit starts on the chosen day (today when none) and the current
        version ends then; an edit on the current version's own first day
        replaces it, or starts tomorrow when doses were already recorded.
        """
        plan, current = self._revisable(circle_id, plan_id, body)
        today = patient_today(self._patient_of(plan), self.now)
        normalized_name = normalize_medication_name(body.name)
        if same_definition(
            self.session, current, body, normalized_name
        ):
            return plan
        if current.effective_from_on > today:
            # Not started yet, or an edit that starts later: this edit takes
            # its place, so a medicine can always be edited again. The one
            # replaced is kept, cancelled, for the audit, as cancel_pending
            # keeps it.
            previous = self._version_before(plan.id, current)
            current.cancelled_at = self.now
            self.session.flush()
            if previous is None:
                return self._start_again(
                    plan, actor_id, body, normalized_name, today
                )
            previous.effective_until_on = None
            self.session.flush()
            current = previous
        effective_from_on, replaces_today = self._revision_start(
            body, current, today
        )
        require_available_name(
            self.session,
            self._patient_of(plan),
            normalized_name,
            body,
            exclude_plan_id=plan.id,
            effective_from_on=effective_from_on,
        )
        self._end_current(current, effective_from_on, replaces_today)
        self._add_next_version(
            plan, actor_id, body, normalized_name, effective_from_on
        )
        return plan

    def _revisable(self, circle_id, plan_id, body):
        """The plan and its current version, when the edit was made on the
        version the app read and the medicine is not stopped."""
        plan = self._plan(circle_id, plan_id)
        if plan.stopped_at is not None:
            raise ValidationFailed(
                "A stopped medication cannot be revised.",
                code="medication_stopped",
            )
        current = self._current_version(plan.id)
        if current.version_number != body.expected_version_number:
            raise Conflict(code="medication_version_conflict")
        return plan, current
