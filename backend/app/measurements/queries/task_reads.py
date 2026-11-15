"""The versions in force and the readings saved for a range of days."""

from datetime import date

from sqlalchemy import select

from app.models import (
    MeasurementPlan,
    MeasurementPlanVersion,
    MeasurementReading,
)


class TaskReads:
    """Reads versions and saved readings."""

    def _versions_in_range(self, circle, start: date, end: date) -> list:
        """The circle's plan versions in force on some day of the range,
        each with its plan."""
        return list(
            self.session.execute(
                select(MeasurementPlan, MeasurementPlanVersion)
                .join(
                    MeasurementPlanVersion,
                    MeasurementPlanVersion.measurement_plan_id
                    == MeasurementPlan.id,
                )
                .where(
                    MeasurementPlan.care_circle_id == circle.id,
                    MeasurementPlanVersion.effective_from_on <= end,
                    (
                        MeasurementPlanVersion.effective_until_on.is_(None)
                        | (MeasurementPlanVersion.effective_until_on > start)
                    ),
                )
            )
        )

    def _saved_readings(self, version_ids, start: date, end: date) -> dict:
        """The readings recorded for those versions in the range, by
        version, day and time."""
        if not version_ids:
            return {}
        readings = self.session.scalars(
            select(MeasurementReading).where(
                MeasurementReading.plan_version_id.in_(version_ids),
                MeasurementReading.scheduled_on.between(start, end),
            )
        )
        return {
            (item.plan_version_id, item.scheduled_on, item.scheduled_time):
            item
            for item in readings
        }
