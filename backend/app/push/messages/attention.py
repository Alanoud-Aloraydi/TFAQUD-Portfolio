"""Who hears that something needs attention, as «يحتاج انتباهك» shows it:
the circle's members and its patient, but not the one who did it, and not
a patient in the simplified mode (their own screens show their day).

The messages are built in the request's transaction and sent (`send_all`)
after it commits, so none tells of a change that was rolled back."""

from collections.abc import Callable, Iterable
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account, CareCircle
from app.push.notify import Push, notify
from app.push.scheduled.audience import read_audience
from app.push.sender import PushMessage
from app.push.targets import Target

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
