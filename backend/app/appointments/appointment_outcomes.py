"""Changing how a visit went, from «السجل»: «حضرت», «ملغى» or «فائت» for a
visit whose time came, and «قادم» again for a cancelled one still ahead.

A visit whose paper has something in it stays «حضرت»: what was written
belongs to a visit that happened. Its empty paper goes with the change.
Nothing is told to the circle: this corrects the record."""

from datetime import datetime, timedelta
from uuid import UUID

from app.appointments.visit_fill import visit_filled
from app.errors import Conflict, ValidationFailed
from app.models import AppointmentVisit
from app.models.appointment import Appointment

# Each choice as it is kept: «فائت» is an open visit marked missed.
_KEPT = {
    "completed": ("completed", False),
    "cancelled": ("cancelled", False),
    "missed": ("scheduled", True),
    "scheduled": ("scheduled", False),
}


class AppointmentOutcomes:
    """The mixin of AppointmentService that changes an outcome."""

    def change_outcome(
        self, circle_id: UUID, appointment_id: UUID, actor_id: UUID,
        outcome: str, expected_updated_at: datetime,
    ) -> Appointment:
        """Keep `outcome` for the visit the app read as it is now."""
        appointment = self._appointment(circle_id, appointment_id)
        if appointment.updated_at != expected_updated_at:
            raise Conflict(code="appointment_changed")
        came = self._moment(
            appointment.care_circle_id,
            appointment.scheduled_on,
            appointment.time_of_day,
        ) <= self.now
        # After its time: how it went. Before it: only a cancelled visit,
        # back to «قادم».
        allowed = (
            {"completed", "cancelled", "missed"} if came
            else {"scheduled", "cancelled"}
            if appointment.status == "cancelled" else set()
        )
        if outcome not in allowed:
            raise ValidationFailed(code="appointment_outcome_closed")
        status, missed = _KEPT[outcome]
        if (status, missed) == (appointment.status, appointment.marked_missed):
            return appointment
        if appointment.status == "completed":
            if visit_filled(self.session, appointment.id):
                raise Conflict(code="appointment_visit_filled")
            empty = self.session.get(AppointmentVisit, appointment.id)
            if empty is not None:
                self.session.delete(empty)
        appointment.status, appointment.marked_missed = status, missed
        appointment.updated_by_account_id = actor_id
        appointment.updated_at = max(
            self.now, appointment.updated_at + timedelta(microseconds=1)
        )
        self.session.flush()
        return appointment
