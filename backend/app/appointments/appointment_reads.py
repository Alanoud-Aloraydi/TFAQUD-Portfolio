"""Reading the patient and one appointment under lock."""

from uuid import UUID

from sqlalchemy import select

from app.errors import NotFound
from app.models import CareCircle
from app.models.appointment import Appointment


class AppointmentReads:
    """Reads the rows a change needs."""

    def _patient(self, circle_id: UUID) -> CareCircle:
        """The circle's patient; 404 when there is none."""
        patient = self.session.scalar(
            select(CareCircle).where(CareCircle.id == circle_id)
        )
        if patient is None:
            raise NotFound()
        return patient

    def _appointment(
        self, circle_id: UUID, appointment_id: UUID
    ) -> Appointment:
        """The patient's appointment with this id; 404 for another patient's.
        """
        patient = self._patient(circle_id)
        appointment = self.session.scalar(
            select(Appointment)
            .where(
                Appointment.id == appointment_id,
                Appointment.care_circle_id == patient.id,
            )
            .with_for_update()
        )
        if appointment is None:
            raise NotFound()
        return appointment
