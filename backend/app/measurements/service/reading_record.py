"""Recording a reading or a skip."""

from datetime import date, time
from uuid import UUID

from sqlalchemy import select

from app.clock import as_utc
from app.errors import Conflict, ValidationFailed
from app.measurements.inputs import ReadingRequest
from app.measurements.service.plan_tables import circle_for
from app.models import MeasurementReading


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
        # judge every reading (0049), so none carries a target.
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
