"""Marking an out-of-range reading as reviewed."""

from uuid import UUID

from sqlalchemy import select

from app.errors import NotFound, ValidationFailed
from app.measurements.ranges import judge, patient_codes
from app.measurements.service.plan_tables import circle_for, planned_state
from app.models import MeasurementReading


class FollowUp:
    """Marks readings reviewed."""

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
