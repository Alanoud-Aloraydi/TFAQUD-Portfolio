"""Who hears of a circle's missed tasks, and sending each their own
message."""

from collections.abc import Callable
from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account, CareCircle, CareCircleManager
from app.push.notify import Push, notify
from app.push.sender import PushMessage


@dataclass(frozen=True)
class Audience:
    """Who hears of one circle's missed tasks: every manager, plus the
    patient if they have an account, each with the name they are called
    by; and the patient's account and name, which the others hear."""

    names: dict[UUID, str | None]
    patient_account_id: UUID | None
    patient_name: str | None


def read_audience(session: Session, patient: CareCircle) -> Audience:
    """Read the circle's audience in the open transaction."""
    recipients = set(
        session.scalars(
            select(CareCircleManager.account_id).where(
                CareCircleManager.care_circle_id == patient.id
            )
        )
    )
    if patient.account_id is not None:
        recipients.add(patient.account_id)
    # Each account's display name, else its first name, in one read.
    rows = session.execute(
        select(Account.id, Account.display_name, Account.first_name).where(
            Account.id.in_(recipients)
        )
    ) if recipients else ()
    known = {row.id: row.display_name or row.first_name for row in rows}
    return Audience(
        names={account_id: known.get(account_id) for account_id in recipients},
        patient_account_id=patient.account_id,
        patient_name=known.get(patient.account_id) or patient.first_name,
    )


def tell_audience(
    audience: Audience,
    title: str,
    kind: str,
    text: Callable[[str | None, bool], str],
) -> None:
    """Send each person of `audience` their own message: `text(name, own)`,
    where `own` is true for the patient."""
    for account_id, name in audience.names.items():
        own = account_id == audience.patient_account_id
        notify(Push((account_id,), PushMessage(title, text(name, own), kind)))


def circle_patient(session: Session, circle_id: UUID) -> CareCircle | None:
    """The circle's patient; None when the circle went since the scan
    began."""
    return session.scalar(
        select(CareCircle).where(CareCircle.id == circle_id)
    )
