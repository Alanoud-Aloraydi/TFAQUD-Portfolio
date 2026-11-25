"""Recording a reading or a skip, outside a plan or for one of its
tasks (which must be due), and following up an out-of-range reading."""

from datetime import date, time
from uuid import UUID

from sqlalchemy import select

from app.clock import as_utc, local_moment, patient_today, patient_zone
from app.errors import Conflict, NotFound, ValidationFailed
from app.measurements.inputs import ReadingRequest
from app.measurements.plans import (
    circle_for,
    plan_times,
    plan_weekdays,
    planned_state,
)
from app.measurements.ranges import judge, patient_codes
from app.models import (
    CareCircle,
    MeasurementPlan,
    MeasurementPlanVersion,
    MeasurementReading,
)


class ReadingRecord:
    """Records readings."""

    def record(
        self,
        circle_id: UUID,
        actor_id: UUID,
        body: ReadingRequest,
        *,
        plan_version_id: UUID | None = None,
        scheduled_on: date | None = None,
        scheduled_time: time | None = None,
    ) -> MeasurementReading:
        """Write one outcome, linked to a task or as a reading outside a
        plan. A task is a version's reading time on a day; a version with
        one reading time needs no `scheduled_time`.
        """
        circle = circle_for(self.session, circle_id)
        # A reading's time carries its offset and is not in the future.
        if body.measured_at is not None:
            if body.measured_at.tzinfo is None:
                raise ValidationFailed(code="measurement_time_offset_required")
            if body.measured_at > self.now:
                raise ValidationFailed(code="future_measurement")
        # Outside a plan: only «read», with no day of a plan. Fixed ranges
        # judge every reading, so none carries a target.
        if plan_version_id is None:
            if scheduled_on is not None or body.outcome != "read":
                raise ValidationFailed(code="measurement_link_required")
        # A reading of a plan's task: the task must exist that day, and it is
        # recorded once.
        else:
            if scheduled_on is None:
                raise ValidationFailed(code="measurement_date_required")
            scheduled_time = self._require_task(
                circle, plan_version_id, scheduled_on, body.kind,
                scheduled_time,
            )
            existing = self.session.scalar(
                select(MeasurementReading)
                .where(
                    MeasurementReading.plan_version_id == plan_version_id,
                    MeasurementReading.scheduled_on == scheduled_on,
                    MeasurementReading.scheduled_time == scheduled_time,
                )
                .with_for_update()
            )
            if existing is not None:
                raise Conflict(code="measurement_reading_conflict")
        # Save the outcome.
        linked = plan_version_id is not None
        reading = MeasurementReading(
            care_circle_id=circle.id,
            plan_version_id=plan_version_id,
            scheduled_on=scheduled_on,
            scheduled_time=scheduled_time if linked else None,
            kind=body.kind,
            outcome=body.outcome,
            measured_at=as_utc(body.measured_at),
            glucose_value=body.glucose_value,
            systolic_value=body.systolic_value,
            diastolic_value=body.diastolic_value,
            conditions=list(body.conditions),
            other_text=body.other_text,
            note=body.note,
            skip_reason_code=body.skip_reason_code,
            skip_reason_note=body.skip_reason_note,
            recorded_by_account_id=actor_id,
            recorded_at=self.now,
        )
        self.session.add(reading)
        self.session.flush()
        return reading

    # Finds the task a reading answers.
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

    # Marks readings reviewed.
    def follow_up(
        self, circle_id: UUID, reading_id: UUID
    ) -> MeasurementReading:
        """Acknowledge a saved reading without changing its numeric result."""
        # The patient's reading (not a skip), locked.
        circle = circle_for(self.session, circle_id)
        reading = self.session.scalar(
            select(MeasurementReading)
            .where(
                MeasurementReading.id == reading_id,
                MeasurementReading.care_circle_id == circle.id,
                MeasurementReading.outcome == "read",
            )
            .with_for_update()
        )
        if reading is None:
            raise NotFound()
        # Only a reading outside its normal range is followed up; marking it
        # again keeps the first time.
        level, _ = judge(
            reading, patient_codes(self.session, circle.id),
            planned_state(self.session, reading),
        )
        if level == "normal":
            raise ValidationFailed(code="measurement_within_target")
        if reading.followed_up_at is None:
            reading.followed_up_at = self.now
            self.session.flush()
        return reading
