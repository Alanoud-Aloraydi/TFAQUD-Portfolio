"""Adding a measurement plan and stopping one."""

from datetime import date
from uuid import UUID

from sqlalchemy import select

from app.clock import patient_today
from app.errors import Conflict, NotFound, ValidationFailed
from app.measurements.inputs import PlanRequest
from app.measurements.service.plan_tables import circle_for
from app.models import CareCircle, MeasurementPlan


class PlanWrites:
    """Adds and stops plans."""

    def create(
        self, circle_id: UUID, actor_id: UUID, body: PlanRequest
    ) -> MeasurementPlan:
        """Create a plan from its first effective day."""
        # Not in the past of the patient's own day; the circle is locked,
        # and has no other plan of this kind in use.
        circle = self.session.get(CareCircle, circle_id, with_for_update=True)
        if circle is None:
            raise NotFound()
        if body.starts_on < patient_today(circle, self.now):
            raise ValidationFailed(code="measurement_start_in_past")
        existing = self.session.scalar(
            select(MeasurementPlan.id).where(
                MeasurementPlan.care_circle_id == circle.id,
                MeasurementPlan.kind == body.kind,
                MeasurementPlan.stopped_at.is_(None),
            )
        )
        if existing is not None:
            raise Conflict(code="measurement_active_plan_exists")
        # The plan and its first version.
        plan = MeasurementPlan(
            care_circle_id=circle.id,
            kind=body.kind,
            created_by_account_id=actor_id,
            created_at=self.now,
        )
        self.session.add(plan)
        self.session.flush()
        self._add_version(plan.id, 1, body.starts_on, body, actor_id)
        return plan

    def stop(
        self, circle_id: UUID, plan_id: UUID, actor_id: UUID
    ) -> MeasurementPlan:
        """Stop future tasks immediately and retain every recorded reading;
        say who stopped it."""
        plan = self._plan(circle_id, plan_id)
        # Stop it once.
        if plan.stopped_at is None:
            plan.stopped_at = self.now
            plan.stopped_by_account_id = actor_id
            self.session.flush()
        return plan

    def _plan(self, circle_id: UUID, plan_id: UUID) -> MeasurementPlan:
        """The circle's measurement plan with this id; 404 for another's."""
        circle = circle_for(self.session, circle_id)
        plan = self.session.scalar(
            select(MeasurementPlan)
            .where(
                MeasurementPlan.id == plan_id,
                MeasurementPlan.care_circle_id == circle.id,
            )
            .with_for_update()
        )
        if plan is None:
            raise NotFound()
        return plan

    def _today(self, care_circle_id: UUID) -> date:
        """The patient's calendar day now, in their own zone."""
        return patient_today(
            self.session.get(CareCircle, care_circle_id), self.now
        )
