"""Circle-scoped appointment and companion reads."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.accounts import accounts_by_id, recorder_response
from app.appointments.companions import companions_for_appointments
from app.models import Account
from app.models.appointment import Appointment


def appointments_for_circle(session: Session, circle_id: UUID) -> list[dict]:
    """Return scheduled and historical visits for one patient."""
    # The patient's appointments in date order, with their companions and who
    # made and last changed each, read once for all.
    appointments = list(session.scalars(
        select(Appointment)
        .where(Appointment.care_circle_id == circle_id)
        .order_by(Appointment.scheduled_on, Appointment.time_of_day)
    ))
    companions = companions_for_appointments(
        session, [item.id for item in appointments]
    )
    accounts = accounts_by_id(
        session,
        {
            account_id
            for item in appointments
            for account_id in (
                item.created_by_account_id, item.updated_by_account_id
            )
            if account_id is not None
        },
    )
    return [
        appointment_view(item, companions[item.id], accounts)
        for item in appointments
    ]


def appointment_view(
    appointment: Appointment,
    companions: list[dict],
    accounts: dict[UUID, Account] | None = None,
) -> dict:
    """Expose only data needed by the appointment screens."""
    accounts = accounts or {}
    return {
        "id": str(appointment.id),
        "specialty": appointment.specialty,
        "kind": appointment.kind,
        "other_text": appointment.other_text,
        "scheduled_on": appointment.scheduled_on.isoformat(),
        "time_of_day": appointment.time_of_day.isoformat(timespec="minutes"),
        "place": appointment.place,
        "remote_method": appointment.remote_method,
        "companions": companions,
        "status": appointment.status,
        "updated_at": appointment.updated_at.isoformat(),
        # Who made it and who last changed it (null when never changed).
        "created_by": recorder_response(
            accounts.get(appointment.created_by_account_id)
        ),
        "updated_by": recorder_response(
            accounts.get(appointment.updated_by_account_id)
        ),
    }
