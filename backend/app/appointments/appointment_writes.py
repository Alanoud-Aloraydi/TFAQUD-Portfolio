"""Changing an appointment and recording how it went."""

from datetime import datetime, timedelta
from uuid import UUID

from app.appointments.inputs import ReviseAppointmentRequest
from app.clock import patient_today
from app.errors import Conflict, ValidationFailed
from app.models import CareCircle
from app.models.appointment import Appointment

# How long before its time an appointment can be marked attended.
ATTEND_EARLY = timedelta(hours=1)
# How many patient days after its own an appointment can still be marked
# attended: as long as «يحتاج انتباهك» lists it (the app's overdueDays).
# After that it counts as missed.
ATTEND_DAYS_AFTER = 2


class AppointmentWrites:
    """Changes and closes appointments; booking is its own mixin."""

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
        # «حضرت» shows on «اليوم», and until it is missed.
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
        if status == "completed" and self._missed(appointment):
            raise ValidationFailed(code="appointment_missed")
        # Close it, say who, and move its change time forward (so the next edit
        # sees it changed).
        appointment.status = status
        appointment.updated_by_account_id = actor_id
        appointment.updated_at = max(
            self.now, appointment.updated_at + timedelta(microseconds=1)
        )
        self.session.flush()
        return appointment

    def _missed(self, appointment: Appointment) -> bool:
        """Whether its day is older than ATTEND_DAYS_AFTER patient days."""
        patient = self.session.get(CareCircle, appointment.care_circle_id)
        today = patient_today(patient, self.now)
        return appointment.scheduled_on < today - timedelta(
            days=ATTEND_DAYS_AFTER
        )
