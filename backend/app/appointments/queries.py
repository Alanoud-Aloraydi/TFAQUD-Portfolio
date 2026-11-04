"""Circle-scoped appointment and companion reads."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account, CareCircleManager, Patient
from app.models.appointment import Appointment


def appointments_for_circle(session: Session, circle_id: UUID) -> list[dict]:
    """Return scheduled and historical visits for one patient."""
    rows = session.execute(
        select(Appointment, Account.display_name, Account.avatar_code)
        .join(Patient, Patient.id == Appointment.patient_id)
        .join(Account, Account.id == Appointment.companion_account_id)
        .where(Patient.care_circle_id == circle_id)
        .order_by(Appointment.scheduled_on, Appointment.time_of_day)
    ).all()
    return [
        {**appointment_view(row, name or ""), "companion_avatar_code": code}
        for row, name, code in rows
    ]


def appointment_view(
    appointment: Appointment, name: str, avatar_code: str | None = None
) -> dict:
    """Expose only data needed by the appointment screens."""
    return {
        "id": str(appointment.id),
        "specialty": appointment.specialty,
        "kind": appointment.kind,
        "other_kind": appointment.other_kind,
        "scheduled_on": appointment.scheduled_on.isoformat(),
        "time_of_day": appointment.time_of_day.isoformat(timespec="minutes"),
        "place": appointment.place,
        "remote_method": appointment.remote_method,
        "companion_account_id": str(appointment.companion_account_id),
        "companion_name": name,
        "companion_avatar_code": avatar_code,
        "status": appointment.status,
        "updated_at": appointment.updated_at.isoformat(),
    }


def companion_name(session: Session, appointment: Appointment) -> str:
    """Resolve the selected member's current display name."""
    return session.scalar(
        select(Account.display_name).where(
            Account.id == appointment.companion_account_id
        )
    ) or ""


def companion_avatar_code(
    session: Session, appointment: Appointment
) -> str | None:
    """Return the selected companion's current character code."""
    return session.scalar(
        select(Account.avatar_code).where(
            Account.id == appointment.companion_account_id
        )
    )


def companions_for_circle(session: Session, circle_id: UUID) -> list[dict]:
    """Offer only current circle managers as visit companions."""
    rows = session.execute(
        select(CareCircleManager.account_id, Account.display_name,
               Account.avatar_code)
        .join(Account, Account.id == CareCircleManager.account_id)
        .where(CareCircleManager.care_circle_id == circle_id)
        .order_by(Account.display_name, CareCircleManager.account_id)
    ).all()
    return [
        {"account_id": str(account_id), "name": name or "",
         "avatar_code": code}
        for account_id, name, code in rows
    ]
