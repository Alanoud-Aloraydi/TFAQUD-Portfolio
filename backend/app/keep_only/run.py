"""Deleting what a KeepPlan found, in one transaction."""

from datetime import datetime

from sqlalchemy import delete, or_
from sqlalchemy.orm import Session

from app.care import CareService
from app.keep_only.plan import KeepPlan
from app.models import CareCircleInvitation, CareCircleRequest, OtpRequest


def apply_keep_plan(session: Session, plan: KeepPlan, now: datetime) -> None:
    """Delete what `plan` found; the kept accounts and their own circles
    stay as they are.

    The circles go first, whole, as the demo reset does: deleting a person
    first would change the doses they recorded, and the database refuses a
    changed dose whose medicine is gone when the transaction ends
    (app/demo_data/lifecycle.py). No circle of a kept account is touched,
    so no kept dose loses its medicine.
    """
    for circle in plan.circles:
        session.delete(circle)
    session.flush()
    other_ids = [person.id for person in plan.accounts]
    session.execute(
        delete(CareCircleInvitation).where(
            CareCircleInvitation.invitee_phone_number.not_in(plan.numbers)
        )
    )
    session.execute(
        delete(CareCircleRequest).where(
            or_(
                CareCircleRequest.patient_phone_number.not_in(plan.numbers),
                CareCircleRequest.requested_by_account_id.in_(other_ids),
            )
        )
    )
    # Each person as the app deletes an account. Their circles are gone
    # already, so nothing more is asked of them here.
    care = CareService(session, now)
    for person in plan.accounts:
        care.delete_account(
            person.id,
            patient_choice="delete",
            delete_last_managed_circles=True,
        )
    session.execute(
        delete(OtpRequest).where(OtpRequest.phone_number.not_in(plan.numbers))
    )
    session.flush()
