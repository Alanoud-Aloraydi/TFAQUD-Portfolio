"""The three things the circle is told of at once: a reading outside its
normal range, a dose skipped, a visit cancelled (attention_texts.py)."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.appointments.kinds import visit_name
from app.models import MedicationPlanVersion, MedicationSchedule
from app.push.attention_texts import (
    APPOINTMENT_TITLE,
    DOSE_TITLE,
    READING_TITLE,
    appointment_cancelled_text,
    dose_skipped_text,
    reading_unusual_text,
)
from app.push.messages.attention import attention_pushes
from app.push.notify import Push
from app.push.targets import (
    appointment_target,
    circle_target,
    dose_target,
    measurement_target,
)


def skipped_dose_pushes(
    session: Session, circle_id: UUID, record, actor_id: UUID
) -> list[Push]:
    """«دواء خالد البتراترا تم تخطيه …» for a dose just recorded skipped."""
    if record.outcome != "skipped":
        return []
    medicine = session.scalar(
        select(MedicationPlanVersion.name)
        .join(
            MedicationSchedule,
            MedicationSchedule.plan_version_id == MedicationPlanVersion.id,
        )
        .where(MedicationSchedule.id == record.schedule_id)
    )
    return attention_pushes(
        session, circle_id, actor_id, DOSE_TITLE, "dose_skipped",
        lambda name, own, patient: dose_skipped_text(
            medicine, record.skip_reason_code, record.skip_reason_note,
            name=name, own=own, patient=patient,
        ),
        dose_target(circle_id, record.schedule_id, record.scheduled_on),
    )


def unusual_reading_pushes(
    session: Session, circle_id: UUID, reading, level: str | None,
    actor_id: UUID,
) -> list[Push]:
    """«قياس السكر لـخالد يحتاج انتباهك!» for a reading just saved outside
    its normal range (any `level` but normal; a skip has none)."""
    if level in (None, "normal"):
        return []
    target = circle_target(circle_id)
    if reading.plan_version_id is not None:
        target = measurement_target(
            circle_id, reading.plan_version_id, reading.scheduled_on,
            reading.scheduled_time.strftime("%H:%M"),
        )
    return attention_pushes(
        session, circle_id, actor_id, READING_TITLE, "measurement_unusual",
        lambda name, own, patient: reading_unusual_text(
            reading.kind, name=name, own=own, patient=patient
        ),
        target,
    )


def cancelled_visit_pushes(
    session: Session, circle_id: UUID, appointment, actor_id: UUID
) -> list[Push]:
    """«موعد خالد لجلسة علاج تم إلغاؤه» for a visit just cancelled."""
    if appointment.status != "cancelled":
        return []
    visit = visit_name(appointment.kind, appointment.other_text)
    return attention_pushes(
        session, circle_id, actor_id, APPOINTMENT_TITLE,
        "appointment_cancelled",
        lambda name, own, patient: appointment_cancelled_text(
            visit, name=name, own=own, patient=patient
        ),
        appointment_target(circle_id, appointment.id),
    )
