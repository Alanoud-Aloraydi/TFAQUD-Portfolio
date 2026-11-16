"""Booking the visits of one appointment request."""

from datetime import date
from uuid import UUID, uuid4

from app.appointments.inputs import AppointmentRequest
from app.models.appointment import Appointment


class AppointmentBooking:
    """Creates the visits a booking asks for."""

    def create(
        self, circle_id: UUID, actor_id: UUID, body: AppointmentRequest
    ) -> list[Appointment]:
        """Create the visits of one booking for the circle patient.

        One date is one visit on its own. Several dates ([body.also_on],
        the clinic's sheet) are saved as one appointment each, oldest
        first, sharing a series: each keeps its own attendance, its own
        companions and its own visit paper, and an edit to one never
        reaches the others.
        """
        # Every date in the future, with valid companions; saved with who
        # made them. One date refused refuses the whole booking.
        patient = self._patient(circle_id)
        days = sorted({body.scheduled_on, *body.also_on})
        for day in days:
            self._future(patient.id, body, day)
        self._companions(circle_id, body.companion_account_ids)
        series_id = uuid4() if len(days) > 1 else None
        return [
            self._one(patient.id, actor_id, body, day, series_id)
            for day in days
        ]

    def _one(
        self,
        care_circle_id: UUID,
        actor_id: UUID,
        body: AppointmentRequest,
        day: date,
        series_id: UUID | None,
    ) -> Appointment:
        """One visit of a booking, on [day]."""
        appointment = Appointment(
            care_circle_id=care_circle_id,
            series_id=series_id,
            created_by_account_id=actor_id,
            status="scheduled",
            created_at=self.now,
            updated_at=self.now,
        )
        self._fill(appointment, body)
        appointment.scheduled_on = day
        self.session.add(appointment)
        self.session.flush()
        self._replace_companions(appointment.id, body.companion_account_ids)
        return appointment
