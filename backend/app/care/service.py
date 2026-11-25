"""The care service: every care workflow, run within the caller's
transaction, and what deleting an account does to its circles and to
what holds its phone number."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.care.building import CareBuilding
from app.care.circle_changes import CareCircleChanges
from app.care.invitations import CareInvitations
from app.care.requests import CareRequests
from app.care.rules import CareRules
from app.errors import ValidationFailed
from app.models import (
    Account,
    CareCircle,
    CareCircleInvitation,
    CareCircleManager,
    CareCircleRequest,
    OtpRequest,
)


class CareService(
    CareRules,
    CareBuilding,
    CareRequests,
    CareInvitations,
    CareCircleChanges,
):
    """Coordinate the six core entities using account-before-circle locks."""

    def __init__(self, session: Session, now: datetime):
        """Bind operations to a session and a consistent operation time."""
        self.session = session
        self.now = now
        # The other requests a new circle closed (`CareBuilding`).
        self.superseded_requests: list = []

    # Deletes an account.
    def delete_account(
        self,
        actor_id: UUID,
        patient_choice: str | None = None,
        delete_last_managed_circles: bool = False,
    ) -> None:
        """Resolve patient ownership and every membership before deletion."""
        account = self._lock_accounts(actor_id)[actor_id]
        # Every circle the account is in: the one where it is the patient
        # (which needs its choice), and every one it manages.
        own = self.session.scalar(
            select(CareCircle).where(CareCircle.account_id == actor_id)
        )
        circle_ids = set(
            self.session.scalars(
                select(CareCircleManager.care_circle_id).where(
                    CareCircleManager.account_id == actor_id
                )
            )
        )
        if own:
            circle_ids.add(own.id)
            if patient_choice not in {"delete", "continue"}:
                raise ValidationFailed(
                    "Choose deletion or continued care.",
                    code="patient_choice_required",
                )
        # Settle each circle, in a fixed order so two deletions cannot lock
        # each other.
        for circle_id in sorted(circle_ids):
            self._resolve_account_circle(
                account,
                own,
                circle_id,
                patient_choice,
                delete_last_managed_circles,
            )
        # Nothing addressed to its phone number stays: the requests and
        # invitations still open for it, and its sign-in code requests
        # (with their sends). Then the account goes.
        self._forget_phone(account.phone_number)
        self.session.delete(account)
        self.session.flush()

    def _forget_phone(self, phone: str) -> None:
        """Delete what holds `phone` for someone who is leaving: the open
        requests and invitations to it, and its sign-in code requests."""
        self.session.execute(
            delete(CareCircleRequest).where(
                CareCircleRequest.patient_phone_number == phone,
                CareCircleRequest.status.in_(["pending", "accepted"]),
            )
        )
        self.session.execute(
            delete(CareCircleInvitation).where(
                CareCircleInvitation.invitee_phone_number == phone,
                CareCircleInvitation.status == "pending",
            )
        )
        self.session.execute(
            delete(OtpRequest).where(OtpRequest.phone_number == phone)
        )

    # Resolves a circle of a deleted account.
    def _resolve_account_circle(
        self,
        account: Account,
        own: CareCircle | None,
        circle_id: UUID,
        patient_choice: str | None,
        delete_last_managed_circles: bool,
    ) -> None:
        """Resolve one locked circle before deleting its account."""
        # The patient's own circle goes when they chose to delete it.
        circle = self._lock_circle(circle_id)
        own_circle = own is not None and own.id == circle_id
        if own_circle and patient_choice == "delete":
            self.session.delete(circle)
            self.session.flush()
            return
        # A circle the account manages alone goes too, only when the person
        # confirmed it (never their own circle that goes on).
        if not self._has_other_manager(account.id, circle_id):
            if own_circle or not delete_last_managed_circles:
                raise ValidationFailed(
                    "Another manager must remain.", code="last_manager"
                )
            self.session.delete(circle)
            self.session.flush()
            return
        # The care goes on: the circle keeps the patient's names, birth date,
        # city and avatar without the account (and no name of its own), and
        # the account stops managing.
        if own_circle:
            circle.first_name = account.first_name
            circle.last_name = account.last_name
            circle.birth_date = account.birth_date
            circle.city = account.city
            circle.avatar_code = account.avatar_code
            circle.name = None
            circle.account_id = None
            self.session.flush()
        self._remove_manager(account.id, circle_id)
