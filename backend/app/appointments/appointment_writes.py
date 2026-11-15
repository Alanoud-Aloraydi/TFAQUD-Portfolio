"""Adding an appointment, changing it, and recording how it went."""

from datetime import datetime, timedelta
from uuid import UUID

from app.appointments.inputs import (
    AppointmentRequest,
    ReviseAppointmentRequest,
)
from app.errors import Conflict, ValidationFailed
from app.models.appointment import Appointment

# How long before its time an appointment can be marked attended.
ATTEND_EARLY = timedelta(hours=1)


class AppointmentWrites:
    """Adds, changes and closes appointments."""

    def create(
        self, circle_id: UUID, actor_id: UUID, body: AppointmentRequest
    ) -> Appointment:
        """Create a visit for the circle patient."""
        # In the future, with valid companions; saved with who made it.
        patient = self._patient(circle_id)
        self._future(patient.id, body)
        self._companions(circle_id, body.companion_account_ids)
        appointment = Appointment(
            care_circle_id=patient.id,
            created_by_account_id=actor_id,
            status="scheduled",
            created_at=self.now,
            updated_at=self.now,
        )
        self._fill(appointment, body)
        self.session.add(appointment)
        self.session.flush()
        self._replace_companions(appointment.id, body.companion_account_ids)
        return appointment

    def revise(
        self, circle_id: UUID, appointment_id: UUID, actor_id: UUID,
        body: ReviseAppointmentRequest,
    ) -> Appointment:
        """Revise a scheduled visit without replacing its identity."""
        # Only an open appointment the app read as it is now, still in the
        # future, with valid companions.
        appointment = self._appointment(circle_id, appointment_id)
        if appointment.status != "scheduled":
            raise Conflict(code="appointment_already_closed")
        if appointment.updated_at != body.expected_updated_at:
            raise Conflict(code="appointment_changed")
        self._future(appointment.care_circle_id, body)
        self._companions(circle_id, body.companion_account_ids)
        # Save the edit, say who, and move its change time forward (so the next
        # edit sees it changed).
        self._fill(appointment, body)
        self._replace_companions(appointment.id, body.companion_account_ids)
        appointment.updated_by_account_id = actor_id
        appointment.updated_at = max(
            self.now, appointment.updated_at + timedelta(microseconds=1)
        )
        self.session.flush()
        return appointment

    def set_status(
        self, circle_id: UUID, appointment_id: UUID, actor_id: UUID,
        status: str, expected_updated_at: datetime,
    ) -> Appointment:
        """Record an explicit attended or cancelled outcome."""
        # Only an open appointment the app read as it is now; one can be
        # marked attended from an hour before its time (ATTEND_EARLY), as
        # «حضرت» shows on «اليوم», not earlier.
        appointment = self._appointment(circle_id, appointment_id)
        if appointment.status != "scheduled":
            raise Conflict(code="appointment_already_closed")
        if appointment.updated_at != expected_updated_at:
            raise Conflict(code="appointment_changed")
        if status == "completed" and self._moment(
            appointment.care_circle_id,
            appointment.scheduled_on,
            appointment.time_of_day,
        ) > self.now + ATTEND_EARLY:
            raise ValidationFailed(code="appointment_not_started")
        # Close it, say who, and move its change time forward (so the next edit
        # sees it changed).
        appointment.status = status
        appointment.updated_by_account_id = actor_id
        appointment.updated_at = max(
            self.now, appointment.updated_at + timedelta(microseconds=1)
        )
        self.session.flush()
        return appointment
