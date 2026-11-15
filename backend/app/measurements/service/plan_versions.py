"""Writing one version of a plan with its days and reading times."""

from datetime import date
from uuid import UUID

from app.measurements.inputs import PlanRequest
from app.models import (
    MeasurementPlanTime,
    MeasurementPlanVersion,
    MeasurementPlanWeekday,
)


class PlanVersions:
    """Writes plan versions."""

    def _add_version(
        self,
        measurement_plan_id: UUID,
        version_number: int,
        effective: date,
        body: PlanRequest,
        actor_id: UUID | None,
    ) -> MeasurementPlanVersion:
        """A new version with its weekdays and reading times."""
        version = MeasurementPlanVersion(
            measurement_plan_id=measurement_plan_id,
            version_number=version_number,
            effective_from_on=effective,
            created_by_account_id=actor_id,
            missed_after_minutes=body.missed_after_minutes,
        )
        self.session.add(version)
        self.session.flush()
        self._add_days_and_times(version.id, body)
        return version

    def _add_days_and_times(
        self, plan_version_id: UUID, body: PlanRequest
    ) -> None:
        """Save the version's weekdays and planned reading times."""
        self.session.add_all(
            MeasurementPlanWeekday(
                plan_version_id=plan_version_id, weekday=weekday
            )
            for weekday in sorted(body.weekdays)
        )
        self.session.add_all(
            MeasurementPlanTime(
                plan_version_id=plan_version_id,
                time_of_day=item.time_of_day,
                measurement_state=item.measurement_state,
            )
            for item in body.sorted_times
        )
        self.session.flush()
