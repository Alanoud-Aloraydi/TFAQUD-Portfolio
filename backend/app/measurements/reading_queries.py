"""The normal ranges and the saved readings of a circle, and the patient's
first day with something saved in «السجل» (the app goes back no further)."""

from datetime import date, datetime, timedelta
from uuid import UUID

from sqlalchemy import and_, func, or_, select
from sqlalchemy.orm import Session

from app.accounts import accounts_by_id
from app.clock import local_moment, patient_zone
from app.measurements.plans import circle_for
from app.measurements.ranges import all_ranges, patient_codes
from app.measurements.responses import reading_response
from app.models import MeasurementPlanTime, MeasurementReading


class Readings:
    """Reads ranges and readings."""

    def ranges(self, circle_id: UUID) -> dict:
        """Return the fixed normal ranges for this patient's conditions."""
        circle = circle_for(self.session, circle_id)
        codes = patient_codes(self.session, circle.id)
        return {
            # The conditions that choose a range, from the medical file.
            "conditions": sorted(codes & {"diabetes", "hypertension"}),
            "ranges": all_ranges(codes),
        }

    def readings(self, circle_id: UUID, start: date, end: date) -> list[dict]:
        """Return recorded readings and skips in the requested date range,
        whose days are the patient's own."""
        circle = circle_for(self.session, circle_id)
        # Readings measured in the range (the patient's days), and skips of
        # tasks in it, the last recorded first.
        zone = patient_zone(circle)
        lower = local_moment(start, datetime.min.time(), zone)
        upper = local_moment(
            end + timedelta(days=1), datetime.min.time(), zone
        )
        return self._responses(
            circle.id,
            or_(
                and_(
                    MeasurementReading.outcome == "read",
                    MeasurementReading.measured_at >= lower,
                    MeasurementReading.measured_at < upper,
                ),
                and_(
                    MeasurementReading.outcome == "skipped",
                    MeasurementReading.scheduled_on.between(start, end),
                ),
            ),
        )

    def all_readings(self, circle_id: UUID) -> list[dict]:
        """Return all saved outcomes for the circle's PDF export."""
        circle = circle_for(self.session, circle_id)
        return self._responses(circle.id)

    def _responses(self, circle_id: UUID, *conditions) -> list[dict]:
        """The circle's readings matching `conditions`, the last recorded
        first, each judged by its normal range, with who recorded it."""
        rows = list(
            self.session.execute(
                select(MeasurementReading, MeasurementPlanTime)
                .outerjoin(
                    MeasurementPlanTime,
                    and_(
                        MeasurementPlanTime.plan_version_id
                        == MeasurementReading.plan_version_id,
                        MeasurementPlanTime.time_of_day
                        == MeasurementReading.scheduled_time,
                    ),
                )
                .where(
                    MeasurementReading.care_circle_id == circle_id,
                    *conditions,
                )
                .order_by(MeasurementReading.recorded_at.desc())
            )
        )
        accounts = accounts_by_id(
            self.session,
            {
                reading.recorded_by_account_id
                for reading, _ in rows
                if reading.recorded_by_account_id is not None
            },
        )
        codes = patient_codes(self.session, circle_id)
        return [
            reading_response(
                reading, accounts, codes=codes,
                planned=time.measurement_state if time else None,
            )
            for reading, time in rows
        ]


def first_reading_on(session: Session, circle_id: UUID) -> date | None:
    """The first of the patient's days with a reading (by when it was
    measured) or a skip (by its task's day); None while there is none."""
    circle = circle_for(session, circle_id)
    mine = MeasurementReading.care_circle_id == circle.id
    measured = session.scalar(
        select(func.min(MeasurementReading.measured_at)).where(
            mine, MeasurementReading.outcome == "read"
        )
    )
    skipped = session.scalar(
        select(func.min(MeasurementReading.scheduled_on)).where(
            mine, MeasurementReading.outcome == "skipped"
        )
    )
    days = [skipped] if skipped else []
    if measured:
        days.append(measured.astimezone(patient_zone(circle)).date())
    return min(days, default=None)
