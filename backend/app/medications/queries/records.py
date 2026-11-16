"""The patient of a circle and the dose records of some days."""

from datetime import date
from uuid import UUID

from sqlalchemy import select

from app.errors import NotFound
from app.models import CareCircle, MedicationDoseRecord


class DoseRecords:
    """Reads the patient and the recorded doses."""

    def _patient(self, circle_id: UUID) -> CareCircle:
        """The circle's patient; 404 when there is none."""
        patient = self.session.scalar(
            select(CareCircle).where(CareCircle.id == circle_id)
        )
        if patient is None:
            raise NotFound("The patient does not exist.")
        return patient

    def _records(
        self,
        schedule_ids: set[UUID],
        from_date: date,
        to_date: date,
    ) -> dict[tuple[UUID, date], MedicationDoseRecord]:
        """The dose records of these schedules between the two dates, by
        schedule and day.
        """
        if not schedule_ids:
            return {}
        rows = self.session.scalars(
            select(MedicationDoseRecord).where(
                MedicationDoseRecord.schedule_id.in_(schedule_ids),
                MedicationDoseRecord.scheduled_on.between(
                    from_date, to_date
                ),
            )
        )
        return {(row.schedule_id, row.scheduled_on): row for row in rows}
