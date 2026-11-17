"""Filling an appointment from a request, and its moment in time."""

from datetime import date, datetime, time
from uuid import UUID

from app.appointments.inputs import AppointmentRequest
from app.clock import local_moment, patient_zone
from app.errors import ValidationFailed
from app.models import CareCircle
from app.models.appointment import Appointment


class AppointmentFields:
    """Fills fields and checks the time."""

    @staticmethod
    def _fill(appointment: Appointment, body: AppointmentRequest) -> None:
        """Copy the request into the appointment, with the texts trimmed."""
        clinic = body.specialty.strip() if body.specialty else ""
        appointment.specialty = clinic or None
        appointment.kind = body.kind
        appointment.other_text = (
            body.other_text.strip() if body.other_text else None
        )
        appointment.scheduled_on = body.scheduled_on
        appointment.time_of_day = body.time_of_day
        appointment.place = body.place.strip() if body.place else None
        appointment.remote_method = body.remote_method
        appointment.reminder_lead_minutes = body.reminder_lead_minutes

    def _moment(
        self, care_circle_id: UUID, day: date, time_of_day: time
    ) -> datetime:
        """The instant of a visit: its time is wall clock in the patient's
        own zone, wherever the recorder is."""
        patient = self.session.get(CareCircle, care_circle_id)
        return local_moment(day, time_of_day, patient_zone(patient))

    def _future(
        self,
        care_circle_id: UUID,
        body: AppointmentRequest,
        day: date | None = None,
    ) -> None:
        """Reject newly scheduled visits that have already passed.

        [day] checks one date of a booking of several; without it the
        request's own date.
        """
        if self._moment(
            care_circle_id, day or body.scheduled_on, body.time_of_day
        ) < self.now:
            raise ValidationFailed(code="appointment_time_in_past")
