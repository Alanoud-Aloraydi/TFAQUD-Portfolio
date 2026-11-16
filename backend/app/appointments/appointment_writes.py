"""Adding an appointment, changing it, and recording how it went."""

from datetime import date, datetime, timedelta
from uuid import UUID, uuid4

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
