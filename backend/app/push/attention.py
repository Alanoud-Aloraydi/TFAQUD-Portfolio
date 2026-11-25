"""What the circle is told of at once: a reading outside its normal
range, a dose skipped, a visit cancelled. The circle's members and its
patient hear it, but not the one who did it, and not a patient in the
simplified mode."""

from collections.abc import Callable, Iterable
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import (
    Account,
    CareCircle,
    MedicationPlanVersion,
    MedicationSchedule,
)
from app.models.appointment import visit_name
from app.push.audience import read_audience
from app.push.notify import (
    Push,
    Target,
    appointment_target,
    circle_target,
    dose_target,
    measurement_target,
    notify,
)
from app.push.sender import PushMessage
from app.push.texts import (
    CANCELLED_APPOINTMENT_TITLE,
    SKIPPED_DOSE_TITLE,
    UNUSUAL_READING_TITLE,
    appointment_cancelled_text,
    dose_skipped_text,
    reading_unusual_text,
)


# `text(name, own, patient)`: one person's words.
Words = Callable[[str | None, bool, str | None], str]


def attention_pushes(
    session: Session, circle_id: UUID, actor_id: UUID, title: str,
    kind: str, text: Words, target: Target,
) -> list[Push]:
    """One push for each person to tell, each with their own words."""
    patient = session.get(CareCircle, circle_id)
    if patient is None:
        return []
    audience = read_audience(session, patient)
    simplified = patient.account_id is not None and session.scalar(
        select(Account.app_mode).where(Account.id == patient.account_id)
    ) == "simplified"
    pushes = []
    for account_id, name in audience.names.items():
        own = account_id == audience.patient_account_id
        if account_id == actor_id or (own and simplified):
            continue
        words = text(name, own, audience.patient_name)
        message = PushMessage(title, words, kind, target)
        pushes.append(Push((account_id,), message))
    return pushes


def send_all(pushes: Iterable[Push]) -> None:
    """Send each push, after the commit; nothing here raises."""
    for push in pushes:
        notify(push)


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
        session, circle_id, actor_id, SKIPPED_DOSE_TITLE, "dose_skipped",
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
        session, circle_id, actor_id, UNUSUAL_READING_TITLE,
        "measurement_unusual",
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
        session, circle_id, actor_id, CANCELLED_APPOINTMENT_TITLE,
        "appointment_cancelled",
        lambda name, own, patient: appointment_cancelled_text(
            visit, name=name, own=own, patient=patient
        ),
        appointment_target(circle_id, appointment.id),
    )
