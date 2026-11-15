"""The scheduled task a reading answers, checked."""

from datetime import date, time
from uuid import UUID

from sqlalchemy import select

from app.clock import local_moment, patient_today, patient_zone
from app.errors import NotFound, ValidationFailed
from app.measurements.service.plan_tables import plan_times, plan_weekdays
from app.models import CareCircle, MeasurementPlan, MeasurementPlanVersion


class ReadingTask:
    """Finds the task a reading answers."""

    def _require_task(
        self,
        circle: CareCircle,
        plan_version_id: UUID,
        scheduled_on: date,
        kind: str,
        scheduled_time: time | None,
    ) -> time:
        """The reading time this task is, after checking the task exists."""
        if scheduled_on > patient_today(circle, self.now):
            raise ValidationFailed(code="future_measurement_task")
        # The circle's plan of this kind with this version, its plan row
        # locked so the task is recorded once.
        row = self.session.execute(
            select(MeasurementPlan, MeasurementPlanVersion)
            .join(
                MeasurementPlanVersion,
                MeasurementPlanVersion.measurement_plan_id
                == MeasurementPlan.id,
            )
            .where(
                MeasurementPlanVersion.id == plan_version_id,
                MeasurementPlan.care_circle_id == circle.id,
                MeasurementPlan.kind == kind,
            )
            .with_for_update(of=MeasurementPlan)
        ).first()
        if row is None:
            raise NotFound()
        plan, version = row
        # Without a time: fine while the version has one reading time.
        times = [
            item.time_of_day
            for item in plan_times(self.session, [version.id])[version.id]
        ]
        if scheduled_time is None:
            if len(times) != 1:
                raise ValidationFailed(code="measurement_time_required")
            scheduled_time = times[0]
        # The task exists only at one of the version's times, on a day it is in
        # force and one of its weekdays, and before the plan was stopped.
        weekdays = plan_weekdays(self.session, [version.id])[version.id]
        if (
            scheduled_time not in times
            or scheduled_on < version.effective_from_on
            or (
                version.effective_until_on is not None
                and scheduled_on >= version.effective_until_on
            )
            or scheduled_on.isoweekday() not in weekdays
            or (
                plan.stopped_at is not None
                and local_moment(
                    scheduled_on, scheduled_time, patient_zone(circle)
                ) >= plan.stopped_at
            )
        ):
            raise NotFound()
        return scheduled_time
