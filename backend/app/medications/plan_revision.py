"""Editing a medicine: a new version from the day it starts, the current
one ended the day before, and nothing at all when the edit is the same as
the version it edits."""

from datetime import timedelta
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.clock import patient_today
from app.errors import Conflict, ValidationFailed
from app.medications.inputs import PlanRequest, RevisePlanRequest
from app.medications.plan_versions import (
    add_plan_version,
    normalize_medication_name,
    require_available_name,
)
from app.medications.schedules import load_days
from app.models import (
    MedicationPlan,
    MedicationPlanVersion,
    MedicationSchedule,
)


def same_definition(
    session: Session,
    version: MedicationPlanVersion,
    body: PlanRequest,
    normalized_name: str,
) -> bool:
    """Return whether a request exactly matches a stored version."""
    # First the medicine's own fields, which need no extra reading.
    fields_match = (
        version.normalized_name == normalized_name
        and version.name == body.name
        and version.strength_value == body.strength_value
        and version.strength_unit == body.strength_unit
        and version.dosage_form == body.dosage_form
        and version.reason_for_use == body.reason_for_use
        and version.instructions == body.instructions
        and version.missed_after_minutes == body.missed_after_minutes
        and version.treatment_starts_on == body.treatment_starts_on
        and version.treatment_ends_on == body.treatment_ends_on
    )
    if not fields_match:
        return False
    # Then the dose times: each one as a set of (time, dose, unit,
    # instructions, repeat, kind of day, day), so their order does not matter.
    schedules = list(
        session.scalars(
            select(MedicationSchedule).where(
                MedicationSchedule.plan_version_id == version.id
            )
        )
    )
    days = load_days(session, schedules)
    stored = {
        (
            schedule.time_of_day,
            schedule.dose_value,
            schedule.dose_unit,
            schedule.instructions,
            schedule.repeat,
            kind,
            day,
        )
        for schedule in schedules
        for kind, values in (
            ("weekday", days[schedule.id].weekdays),
            ("month_day", days[schedule.id].month_days),
            ("interval", _interval(schedule.interval_days)),
        )
        for day in values
    }
    requested = {
        (
            item.time_of_day,
            item.dose_value,
            item.dose_unit,
            item.instructions,
            item.repeat,
            kind,
            day,
        )
        for item in body.schedules
        for kind, values in (
            ("weekday", item.weekdays),
            ("month_day", item.month_days),
            ("interval", _interval(item.interval_days)),
        )
        for day in values
    }
    return stored == requested


def _interval(interval_days: int | None) -> tuple[int, ...]:
    """An interval schedule's one number, compared like a day."""
    return () if interval_days is None else (interval_days,)


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

    # Starts, ends and adds versions.
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
