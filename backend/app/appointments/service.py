"""Changing a circle's appointments, inside one transaction: booking the
visits of a request, revising one, choosing who goes with the patient, and
recording how a visit went."""

from datetime import date, datetime, time, timedelta
from uuid import UUID, uuid4

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.appointments.inputs import (
    AppointmentRequest,
    ReviseAppointmentRequest,
)
from app.appointments.visits import visit_filled
from app.clock import local_moment, patient_today, patient_zone
from app.errors import Conflict, NotFound, ValidationFailed
from app.models import Account, AppointmentVisit, CareCircle, CareCircleManager
from app.models.appointment import Appointment, AppointmentCompanion


# How long before its time an appointment can be marked attended.
ATTEND_EARLY = timedelta(hours=1)

# How many patient days after its own an appointment can still be marked
# attended: as long as «يحتاج انتباهك» lists it (the app's overdueDays).
# After that it counts as missed.
ATTEND_DAYS_AFTER = 2


# Each choice as it is kept: «فائت» is an open visit marked missed.
_KEPT = {
    "completed": ("completed", False),
    "cancelled": ("cancelled", False),
    "missed": ("scheduled", True),
    "scheduled": ("scheduled", False),
}


class AppointmentService:
    """Keep appointment writes within one authorized circle."""

    def __init__(self, session: Session, now: datetime):
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    # Creates the visits a booking asks for.
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

    # Changing a visit and closing it.
    def revise(
        self, circle_id: UUID, appointment_id: UUID, actor_id: UUID,
        body: ReviseAppointmentRequest,
    ) -> Appointment:
        """Revise a scheduled visit without replacing its identity."""
        # Only an open appointment the app read as it is now, still in the
        # future, with valid companions.
        appointment = self._open(circle_id, appointment_id)
        self._as_read(appointment, body.expected_updated_at)
        self._future(appointment.care_circle_id, body)
        self._companions(circle_id, body.companion_account_ids)
        self._fill(appointment, body)
        # Moved ahead, it is not missed any more.
        appointment.marked_missed = False
        self._replace_companions(appointment.id, body.companion_account_ids)
        return self._touched(appointment, actor_id)

    def set_status(
        self, circle_id: UUID, appointment_id: UUID, actor_id: UUID,
        status: str, expected_updated_at: datetime,
    ) -> Appointment:
        """Record an explicit attended or cancelled outcome."""
        # Only an open appointment the app read as it is now; one can be
        # marked attended from an hour before its time (ATTEND_EARLY), as
        # «حضرت» shows on «اليوم», and until it is missed.
        appointment = self._open(circle_id, appointment_id)
        self._as_read(appointment, expected_updated_at)
        starts = self._starts_at(appointment)
        if status == "completed" and starts > self.now + ATTEND_EARLY:
            raise ValidationFailed(code="appointment_not_started")
        if status == "completed" and self._missed(appointment):
            raise ValidationFailed(code="appointment_missed")
        appointment.status = status
        appointment.marked_missed = False
        return self._touched(appointment, actor_id)

    def _missed(self, appointment: Appointment) -> bool:
        """Whether its day is older than ATTEND_DAYS_AFTER patient days."""
        patient = self.session.get(CareCircle, appointment.care_circle_id)
        today = patient_today(patient, self.now)
        return (today - appointment.scheduled_on).days > ATTEND_DAYS_AFTER

    # «حضرت», «ملغى», «فائت» or «قادم» again, chosen from «السجل».
    def change_outcome(
        self, circle_id: UUID, appointment_id: UUID, actor_id: UUID,
        outcome: str, expected_updated_at: datetime,
    ) -> Appointment:
        """Keep `outcome` for the visit the app read as it is now."""
        appointment = self._appointment(circle_id, appointment_id)
        self._as_read(appointment, expected_updated_at)
        came = self._starts_at(appointment) <= self.now
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
        return self._touched(appointment, actor_id)

    # Reads the rows a change needs.
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

    def _open(self, circle_id: UUID, appointment_id: UUID) -> Appointment:
        """The appointment, still scheduled; 409 once it was closed."""
        appointment = self._appointment(circle_id, appointment_id)
        if appointment.status != "scheduled":
            raise Conflict(code="appointment_already_closed")
        return appointment

    @staticmethod
    def _as_read(appointment: Appointment, expected_updated_at: datetime):
        """409 `appointment_changed` unless the app read it as it is now."""
        if appointment.updated_at != expected_updated_at:
            raise Conflict(code="appointment_changed")

    def _touched(self, appointment: Appointment, actor_id: UUID):
        """Say who changed it, and move its change time forward so the next
        edit sees it changed."""
        appointment.updated_by_account_id = actor_id
        appointment.updated_at = max(
            self.now, appointment.updated_at + timedelta(microseconds=1)
        )
        self.session.flush()
        return appointment

    # Checks and replaces companions.
    def _companions(self, circle_id: UUID, account_ids: list[UUID]) -> None:
        """422 unless every companion is a manager of the circle with an
        account (their rows are locked meanwhile). No companion is fine.
        """
        if not account_ids:
            return
        members = set(self.session.scalars(
            select(CareCircleManager.account_id)
            .join(Account, Account.id == CareCircleManager.account_id)
            .where(
                CareCircleManager.care_circle_id == circle_id,
                CareCircleManager.account_id.in_(account_ids),
            )
            .with_for_update()
        ))
        if members != set(account_ids):
            raise ValidationFailed(code="appointment_invalid_companion")

    def _replace_companions(
        self, appointment_id: UUID, account_ids: list[UUID]
    ) -> None:
        """Make the appointment's companions exactly these accounts."""
        self.session.execute(
            delete(AppointmentCompanion).where(
                AppointmentCompanion.appointment_id == appointment_id
            )
        )
        self.session.add_all(
            AppointmentCompanion(
                appointment_id=appointment_id, account_id=account_id
            )
            for account_id in account_ids
        )
        self.session.flush()

    # Fills fields and checks the time.
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

    def _starts_at(self, appointment: Appointment) -> datetime:
        """The instant the appointment's visit starts."""
        a = appointment
        return self._moment(a.care_circle_id, a.scheduled_on, a.time_of_day)

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
