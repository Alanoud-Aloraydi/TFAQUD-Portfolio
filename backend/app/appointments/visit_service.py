"""Transactional written and voice notes for completed appointments."""

from datetime import datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.appointments.visit_reads import VisitReads
from app.errors import ValidationFailed
from app.models import AppointmentVisit

MAX_AUDIO_BYTES = 5 * 1024 * 1024


class VisitService(VisitReads):
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
