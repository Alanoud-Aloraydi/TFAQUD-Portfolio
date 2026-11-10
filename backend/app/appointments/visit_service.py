"""Transactional written and voice notes for completed appointments."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import Conflict, NotFound, ValidationFailed
from app.models import Appointment, AppointmentVisit, Patient

MAX_AUDIO_BYTES = 5 * 1024 * 1024


class VisitService:
    """Store one visit paper while retaining appointment ownership."""

    def __init__(self, session: Session, now: datetime):
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    def get(
        self, circle_id: UUID, appointment_id: UUID
    ) -> AppointmentVisit | None:
        """Read a visit after checking the circle's patient."""
        self._appointment(circle_id, appointment_id, lock=False)
        return self.session.get(AppointmentVisit, appointment_id)

    def save_text(
        self, circle_id: UUID, appointment_id: UUID, actor_id: UUID,
        summary: str | None, recommendations: str | None,
        follow_up: str | None,
    ) -> AppointmentVisit:
        """Replace the report's written fields without touching its audio."""
        self._completed(circle_id, appointment_id)
        visit = self._visit(appointment_id)
        visit.summary = self._clean(summary)
        visit.recommendations = self._clean(recommendations)
        visit.follow_up = self._clean(follow_up)
        visit.updated_by_account_id = actor_id
        visit.updated_at = self.now
        self.session.flush()
        return visit

    def save_audio(
        self, circle_id: UUID, appointment_id: UUID, actor_id: UUID,
        audio: bytes,
    ) -> AppointmentVisit:
        """Replace the M4A voice note with a size-bounded recording."""
        self._completed(circle_id, appointment_id)
        if (
            not audio or len(audio) > MAX_AUDIO_BYTES
            or audio[4:8] != b"ftyp"
        ):
            raise ValidationFailed(code="appointment_invalid_audio")
        visit = self._visit(appointment_id)
        visit.audio = audio
        visit.updated_by_account_id = actor_id
        visit.updated_at = self.now
        self.session.flush()
        return visit

    def remove_audio(
        self, circle_id: UUID, appointment_id: UUID, actor_id: UUID
    ) -> AppointmentVisit:
        """Delete only the voice note and retain the written report."""
        self._completed(circle_id, appointment_id)
        visit = self._visit(appointment_id)
        visit.audio = None
        visit.updated_by_account_id = actor_id
        visit.updated_at = self.now
        self.session.flush()
        return visit

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
        query = select(Appointment).join(
            Patient, Patient.id == Appointment.patient_id
        ).where(
            Appointment.id == appointment_id,
            Patient.care_circle_id == circle_id,
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


def visit_view(visit: AppointmentVisit | None) -> dict | None:
    """Exclude audio bytes from the JSON visit representation."""
    if visit is None:
        return None
    return {
        "appointment_id": str(visit.appointment_id),
        "summary": visit.summary,
        "recommendations": visit.recommendations,
        "follow_up": visit.follow_up,
        "has_audio": visit.audio is not None,
    }
