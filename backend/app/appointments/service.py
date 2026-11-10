"""Transactional appointment creation, revision, and outcomes."""

from datetime import date, datetime, time, timedelta
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.appointments.inputs import AppointmentRequest
from app.appointments.inputs import ReviseAppointmentRequest
from app.clock import local_moment, patient_zone
from app.errors import Conflict, NotFound, ValidationFailed
from app.models import Account, CareCircleManager, Patient
from app.models.appointment import Appointment, AppointmentCompanion


class AppointmentService:
    """Keep appointment writes within one authorized circle."""

    def __init__(self, session: Session, now: datetime):
        self.session = session
        self.now = now

    def create(
        self, circle_id: UUID, actor_id: UUID, body: AppointmentRequest
    ) -> Appointment:
        """Create a visit for the circle patient."""
        patient = self._patient(circle_id)
        self._future(patient.id, body)
        self._companions(circle_id, body.companion_account_ids)
        appointment = Appointment(
            patient_id=patient.id,
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
        appointment = self._appointment(circle_id, appointment_id)
        if appointment.status != "scheduled":
            raise Conflict(code="appointment_already_closed")
        if appointment.updated_at != body.expected_updated_at:
            raise Conflict(code="appointment_changed")
        self._future(appointment.patient_id, body)
        self._companions(circle_id, body.companion_account_ids)
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
        appointment = self._appointment(circle_id, appointment_id)
        if appointment.status != "scheduled":
            raise Conflict(code="appointment_already_closed")
        if appointment.updated_at != expected_updated_at:
            raise Conflict(code="appointment_changed")
        if status == "completed" and self._moment(
            appointment.patient_id,
            appointment.scheduled_on,
            appointment.time_of_day,
        ) > self.now:
            raise ValidationFailed(code="appointment_not_started")
        appointment.status = status
        appointment.updated_by_account_id = actor_id
        appointment.updated_at = max(
            self.now, appointment.updated_at + timedelta(microseconds=1)
        )
        self.session.flush()
        return appointment

    def _patient(self, circle_id: UUID) -> Patient:
        patient = self.session.scalar(
            select(Patient).where(Patient.care_circle_id == circle_id)
        )
        if patient is None:
            raise NotFound()
        return patient

    def _appointment(
        self, circle_id: UUID, appointment_id: UUID
    ) -> Appointment:
        patient = self._patient(circle_id)
        appointment = self.session.scalar(
            select(Appointment)
            .where(
                Appointment.id == appointment_id,
                Appointment.patient_id == patient.id,
            )
            .with_for_update()
        )
        if appointment is None:
            raise NotFound()
        return appointment

    def _companions(self, circle_id: UUID, account_ids: list[UUID]) -> None:
        members = set(self.session.scalars(
            select(CareCircleManager.account_id)
            .join(Account, Account.id == CareCircleManager.account_id)
            .where(
                CareCircleManager.care_circle_id == circle_id,
                CareCircleManager.account_id.in_(account_ids),
            )
            .with_for_update()
        ))
        if not account_ids or members != set(account_ids):
            raise ValidationFailed(code="appointment_invalid_companion")

    def _replace_companions(
        self, appointment_id: UUID, account_ids: list[UUID]
    ) -> None:
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

    @staticmethod
    def _fill(appointment: Appointment, body: AppointmentRequest) -> None:
        appointment.specialty = body.specialty.strip()
        appointment.kind = body.kind
        appointment.other_kind = (
            body.other_kind.strip() if body.other_kind else None
        )
        appointment.scheduled_on = body.scheduled_on
        appointment.time_of_day = body.time_of_day
        appointment.place = body.place.strip() if body.place else None
        appointment.remote_method = body.remote_method

    def _moment(
        self, patient_id: UUID, day: date, time_of_day: time
    ) -> datetime:
        """The instant of a visit: its time is wall clock in the patient's
        own zone, wherever the recorder is."""
        patient = self.session.get(Patient, patient_id)
        return local_moment(day, time_of_day, patient_zone(patient))

    def _future(self, patient_id: UUID, body: AppointmentRequest) -> None:
        """Reject newly scheduled visits that have already passed."""
        if self._moment(
            patient_id, body.scheduled_on, body.time_of_day
        ) < self.now:
            raise ValidationFailed(code="appointment_time_in_past")
