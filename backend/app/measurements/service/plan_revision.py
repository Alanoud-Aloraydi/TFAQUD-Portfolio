"""Editing a measurement plan from a day on."""

from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import delete, select

from app.errors import Conflict, ValidationFailed
from app.models import (
    MeasurementPlan,
    MeasurementPlanTime,
    MeasurementPlanVersion,
    MeasurementPlanWeekday,
    MeasurementReading,
)


class PlanRevision:
    """Edits plans."""

    def revise(
        self, circle_id: UUID, plan_id: UUID, actor_id: UUID, body
    ) -> MeasurementPlan:
        """Change future occurrences without rewriting prior readings."""
        plan = self._plan(circle_id, plan_id)
        if plan.stopped_at is not None or body.kind != plan.kind:
            raise Conflict(code="measurement_plan_changed")
        versions = list(
            self.session.scalars(
                select(MeasurementPlanVersion)
                .where(MeasurementPlanVersion.measurement_plan_id == plan.id)
                .order_by(MeasurementPlanVersion.version_number)
            )
        )
        latest = versions[-1]
        today = self._today(plan.care_circle_id)
        if latest.version_number != body.expected_version_number:
            raise Conflict(code="measurement_plan_changed")
        if latest.effective_from_on > today:
            # Not started yet, or an edit that starts later: it has no
            # reading, so this edit changes it in place, and a plan can
            # always be edited again.
            effective = body.effective_from_on or latest.effective_from_on
            if effective < today:
                raise ValidationFailed(code="measurement_effective_date")
            if len(versions) > 1:
                previous = versions[-2]
                if effective <= previous.effective_from_on:
                    raise ValidationFailed(code="measurement_effective_date")
                previous.effective_until_on = effective
            self._replace(latest, effective, body, actor_id)
            return plan
        effective = body.effective_from_on or today
        if effective == latest.effective_from_on == today:
            # The plan began today (added or edited today) and the edit is
            # for today too. With no reading under it yet, the edit replaces
            # it; a reading of today keeps the plan it was taken under, and
            # the edit starts tomorrow. Days are the unit of a version.
            if not self._has_readings(latest):
                self._replace(latest, effective, body, actor_id)
                return plan
            effective = today + timedelta(days=1)
        if effective < today or effective <= latest.effective_from_on:
            raise ValidationFailed(code="measurement_effective_date")
        latest.effective_until_on = effective
        self._add_version(
            plan.id, latest.version_number + 1, effective, body, actor_id
        )
        return plan

    def _replace(
        self,
        version: MeasurementPlanVersion,
        effective: date,
        body,
        actor_id: UUID | None = None,
    ) -> None:
        """Change a version that has no history yet, in place."""
        # Take every field of the edit onto the version itself.
        version.effective_from_on = effective
        version.created_by_account_id = actor_id
        version.missed_after_minutes = body.missed_after_minutes
        # Fixed ranges replace a version's own target (0049).
        version.glucose_low = version.glucose_high = None
        version.systolic_limit = version.diastolic_limit = None
        # Its reading times and weekdays are replaced too.
        for model in (MeasurementPlanTime, MeasurementPlanWeekday):
            self.session.execute(
                delete(model).where(model.plan_version_id == version.id)
            )
        self.session.flush()
        self._add_days_and_times(version.id, body)

    def _has_readings(self, version: MeasurementPlanVersion) -> bool:
        """Whether any task of this version has an outcome."""
        return self.session.scalar(
            select(MeasurementReading.id)
            .where(MeasurementReading.plan_version_id == version.id)
            .limit(1)
        ) is not None
