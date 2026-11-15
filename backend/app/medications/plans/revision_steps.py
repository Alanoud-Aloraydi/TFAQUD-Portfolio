"""The steps of an edit: the day it starts, ending the current version
and adding the next."""

from datetime import timedelta
from uuid import UUID

from sqlalchemy import func, select

from app.errors import ValidationFailed
from app.medications.plan_versions import add_plan_version
from app.models import MedicationPlanVersion


class PlanRevisionSteps:
    """Starts, ends and adds versions."""

    def _revision_start(self, body, current, today):
        """The day the edit starts, and whether it replaces a version that
        began that same day."""
        effective_from_on = body.effective_from_on or today
        if effective_from_on < today:
            raise ValidationFailed(
                "A revision cannot start in the past.",
                code="medication_revision_date",
            )
        # The current version began today (the medicine was added or edited
        # today) and the edit is for today too: it replaces that version.
        # Days are the unit of a version, so two cannot start the same day.
        replaces_today = effective_from_on == current.effective_from_on
        if replaces_today and self._has_doses(current):
            # A dose of today was already recorded under it. That dose keeps
            # the plan it was given under: the edit starts tomorrow.
            effective_from_on = today + timedelta(days=1)
            replaces_today = False
        if (
            not replaces_today
            and effective_from_on <= current.effective_from_on
        ):
            raise ValidationFailed(
                "A revision must follow the current version.",
                code="medication_revision_date",
            )
        if (
            body.treatment_ends_on is not None
            and body.treatment_ends_on < effective_from_on
        ):
            raise ValidationFailed(
                "A revision cannot start after treatment ends.",
                code="medication_revision_date",
            )
        return effective_from_on, replaces_today

    def _end_current(self, current, effective_from_on, replaces_today):
        """End the current version where the edit starts; one it replaces
        is kept, cancelled, for the audit, like a cancelled future edit."""
        if replaces_today:
            current.cancelled_at = self.now
            self.session.flush()
        else:
            current.effective_until_on = effective_from_on

    def _add_next_version(
        self, plan, actor_id, body, normalized_name, effective_from_on
    ):
        """Add the edit as the plan's next version."""
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
            effective_from_on,
        )

    def _version_before(
        self, plan_id: UUID, version: MedicationPlanVersion
    ) -> MedicationPlanVersion | None:
        """The version in effect until [version] starts, or None when
        [version] is the first."""
        return self.session.scalar(
            select(MedicationPlanVersion).where(
                MedicationPlanVersion.medication_plan_id == plan_id,
                MedicationPlanVersion.effective_until_on
                == version.effective_from_on,
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        )
