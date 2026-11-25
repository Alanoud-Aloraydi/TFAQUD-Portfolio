"""Reading a circle's appointments and their companions: those chosen for a
visit, and the members who may be."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.accounts import accounts_by_id, recorder_response
from app.appointments.visits import filled_visits
from app.models import Account, CareCircle, CareCircleManager
from app.models.appointment import Appointment, AppointmentCompanion


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


def patient_has_account(session: Session, circle_id: UUID) -> bool:
    """Whether the circle's patient has an account, so a phone: without
    one, a visit nobody goes with reminds the circle's leader."""
    return session.scalar(
        select(CareCircle.account_id).where(CareCircle.id == circle_id)
    ) is not None


def appointments_for_circle(session: Session, circle_id: UUID) -> list[dict]:
    """Return scheduled and historical visits for one patient."""
    # The patient's appointments in date order, with their companions and who
    # made and last changed each, read once for all.
    appointments = list(session.scalars(
        select(Appointment)
        .where(Appointment.care_circle_id == circle_id)
        .order_by(Appointment.scheduled_on, Appointment.time_of_day)
    ))
    ids = [item.id for item in appointments]
    companions = companions_for_appointments(session, ids)
    filled = filled_visits(session, ids)
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
        appointment_view(
            item, companions[item.id], accounts, item.id in filled
        )
        for item in appointments
    ]


def appointment_view(
    appointment: Appointment,
    companions: list[dict],
    accounts: dict[UUID, Account] | None = None,
    visit_filled: bool = False,
) -> dict:
    """Expose only data needed by the appointment screens; `visit_filled`:
    its visit paper has something in it (app.appointments.visits)."""
    accounts = accounts or {}
    return {
        "id": str(appointment.id),
        "specialty": appointment.specialty,
        "kind": appointment.kind,
        "other_text": appointment.other_text,
        "scheduled_on": appointment.scheduled_on.isoformat(),
        # The booking it belongs to; null for a visit on its own. The app
        # says «الزيارة 2 من 6» from it and nothing more.
        "series_id": (
            str(appointment.series_id) if appointment.series_id else None
        ),
        "time_of_day": appointment.time_of_day.isoformat(timespec="minutes"),
        "place": appointment.place,
        "remote_method": appointment.remote_method,
        # Minutes before the visit for its near reminder; the day-before
        # one is always set and is not chosen.
        "reminder_lead_minutes": appointment.reminder_lead_minutes,
        "companions": companions,
        "status": appointment.status,
        # «فائت» chosen from «السجل»: an open visit missed at once.
        "marked_missed": appointment.marked_missed,
        # Its «ورقة الزيارة» has something in it, so it stays «حضرت».
        "visit_filled": visit_filled,
        "updated_at": appointment.updated_at.isoformat(),
        # Who made it and who last changed it (null when never changed).
        "created_by": recorder_response(
            accounts.get(appointment.created_by_account_id)
        ),
        "updated_by": recorder_response(
            accounts.get(appointment.updated_by_account_id)
        ),
    }
