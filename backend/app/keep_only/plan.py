"""What `flask keep-only` deletes, found before anything is deleted.

Every account whose number is not kept goes, and every circle that has
such a person in it, as its patient or one of its people, goes whole: a
circle of the kept accounts alone stays as it is. What still waits for a
number that is not kept, or remembers it, goes too: invitations and circle
requests (whatever their status) and sign-in codes.
"""

from collections.abc import Collection
from dataclasses import dataclass

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.models import (
    Account,
    CareCircle,
    CareCircleInvitation,
    CareCircleManager,
    CareCircleRequest,
    OtpRequest,
)


@dataclass(frozen=True)
class KeepPlan:
    """The kept numbers and what goes."""

    keep: frozenset[str]
    kept: list[Account]
    missing: list[str]
    accounts: list[Account]
    circles: list[CareCircle]
    invitations: int
    requests: int
    sign_ins: int

    @property
    def numbers(self) -> tuple[str, ...]:
        """The kept numbers, for a query."""
        return tuple(sorted(self.keep))


def keep_plan(session: Session, keep: Collection[str]) -> KeepPlan:
    """Find what goes when only the accounts of `keep` stay."""
    keep = frozenset(keep)
    numbers = tuple(sorted(keep))
    everyone = session.scalars(
        select(Account).order_by(Account.phone_number)
    ).all()
    kept = [person for person in everyone if person.phone_number in keep]
    others = [p for p in everyone if p.phone_number not in keep]
    other_ids = [person.id for person in others]
    circles = session.scalars(
        select(CareCircle)
        .where(
            or_(
                CareCircle.account_id.in_(other_ids),
                CareCircle.id.in_(
                    select(CareCircleManager.care_circle_id).where(
                        CareCircleManager.account_id.in_(other_ids)
                    )
                ),
            )
        )
        .order_by(CareCircle.first_name, CareCircle.id)
    ).all()
    found = {person.phone_number for person in kept}
    return KeepPlan(
        keep=keep,
        kept=kept,
        missing=sorted(keep - found),
        accounts=others,
        circles=list(circles),
        invitations=_count(
            session,
            CareCircleInvitation,
            CareCircleInvitation.invitee_phone_number.not_in(numbers),
        ),
        requests=_count(
            session,
            CareCircleRequest,
            or_(
                CareCircleRequest.patient_phone_number.not_in(numbers),
                CareCircleRequest.requested_by_account_id.in_(other_ids),
            ),
        ),
        sign_ins=_count(
            session, OtpRequest, OtpRequest.phone_number.not_in(numbers)
        ),
    )


def _count(session: Session, model, condition) -> int:
    """How many rows of `model` meet `condition`."""
    return session.scalar(
        select(func.count()).select_from(model).where(condition)
    )
