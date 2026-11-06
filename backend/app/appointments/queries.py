"""Circle-scoped appointment and companion reads."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account, CareCircleManager, Patient
from app.models.appointment import Appointment, AppointmentCompanion


def appointments_for_circle(session: Session, circle_id: UUID) -> list[dict]:
    """Return scheduled and historical visits for one patient."""
    appointments = list(session.scalars(
        select(Appointment)
        .join(Patient, Patient.id == Appointment.patient_id)
        .where(Patient.care_circle_id == circle_id)
        .order_by(Appointment.scheduled_on, Appointment.time_of_day)
    ))
    companions = companions_for_appointments(
        session, [item.id for item in appointments]
    )
    return [
        appointment_view(item, companions[item.id])
        for item in appointments
    ]


def appointment_view(
    appointment: Appointment, companions: list[dict]
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
        "companions": companions,
        "status": appointment.status,
        "updated_at": appointment.updated_at.isoformat(),
    }


def companions_for_appointments(
    session: Session, appointment_ids: list[UUID]
) -> dict[UUID, list[dict]]:
    """Resolve selected members in one query, including past companions."""
    result: dict[UUID, list[dict]] = {
        appointment_id: [] for appointment_id in appointment_ids
    }
    if not appointment_ids:
        return result
    rows = session.execute(
        select(
            AppointmentCompanion.appointment_id,
            Account.id,
            Account.display_name,
            Account.avatar_code,
        )
        .join(Account, Account.id == AppointmentCompanion.account_id)
        .where(AppointmentCompanion.appointment_id.in_(appointment_ids))
        .order_by(Account.display_name, Account.id)
    )
    for appointment_id, account_id, name, avatar_code in rows:
        result[appointment_id].append({
            "account_id": str(account_id),
            "name": name or "",
            "avatar_code": avatar_code,
        })
    return result


def companions_for_circle(session: Session, circle_id: UUID) -> list[dict]:
    """Offer current circle managers as visit companions, other than the
    patient themselves: a patient who manages their own circle is not their
    own companion."""
    patient_account_id = session.scalar(
        select(Patient.account_id).where(Patient.care_circle_id == circle_id)
    )
    query = (
        select(CareCircleManager.account_id, Account.display_name,
               Account.avatar_code)
        .join(Account, Account.id == CareCircleManager.account_id)
        .where(CareCircleManager.care_circle_id == circle_id)
    )
    if patient_account_id is not None:
        query = query.where(CareCircleManager.account_id != patient_account_id)
    rows = session.execute(
        query.order_by(Account.display_name, CareCircleManager.account_id)
    ).all()
    return [
        {"account_id": str(account_id), "name": name or "",
         "avatar_code": code}
        for account_id, name, code in rows
    ]
