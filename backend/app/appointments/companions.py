"""Companions: those chosen for some appointments, and those who may be."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account, CareCircle, CareCircleManager
from app.models.appointment import AppointmentCompanion


def companions_for_appointments(
    session: Session, appointment_ids: list[UUID]
) -> dict[UUID, list[dict]]:
    """Resolve selected members in one query, including past companions."""
    # Every appointment gets a list, even an empty one; one read for all their
    # companions.
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
    # The circle's managers, by name, but not the patient (a patient in the
    # full app manages their own circle, and does not go with themself).
    patient_account_id = session.scalar(
        select(CareCircle.account_id).where(CareCircle.id == circle_id)
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
