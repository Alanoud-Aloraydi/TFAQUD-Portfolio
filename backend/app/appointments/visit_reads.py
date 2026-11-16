"""Reading a completed appointment and its visit paper."""

from uuid import UUID

from sqlalchemy import select

from app.errors import Conflict, NotFound
from app.models import Appointment, AppointmentVisit


class VisitReads:
    """Reads visits and their appointments."""

    def _visit(self, appointment_id: UUID) -> AppointmentVisit:
        """The appointment's visit notes, made empty when there are none yet.
        """
        visit = self.session.get(AppointmentVisit, appointment_id)
        if visit is None:
            visit = AppointmentVisit(
                appointment_id=appointment_id,
                updated_at=self.now,
            )
            self.session.add(visit)
        return visit

    def _completed(self, circle_id: UUID, appointment_id: UUID) -> None:
        """Lock the appointment; 409 unless it is marked done (notes come after
        the visit).
        """
        appointment = self._appointment(circle_id, appointment_id, lock=True)
        if appointment.status != "completed":
            raise Conflict(code="appointment_visit_not_completed")

    def _appointment(
        self, circle_id: UUID, appointment_id: UUID, *, lock: bool
    ) -> Appointment:
        """The circle's appointment with this id, locked when `lock`; 404 for
        another circle's.
        """
        query = select(Appointment).where(
            Appointment.id == appointment_id,
            Appointment.care_circle_id == circle_id,
        )
        if lock:
            query = query.with_for_update(of=Appointment)
        appointment = self.session.scalar(query)
        if appointment is None:
            raise NotFound()
        return appointment

    @staticmethod
    def _clean(value: str | None) -> str | None:
        """Trimmed text, or None for none or only spaces."""
        if value is None:
            return None
        return value.strip() or None
