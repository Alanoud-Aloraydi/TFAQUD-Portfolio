"""Deleting an account: its circles resolved first, and what holds its
phone number forgotten."""

from uuid import UUID

from sqlalchemy import delete, select

from app.errors import ValidationFailed
from app.models import (
    CareCircle,
    CareCircleInvitation,
    CareCircleManager,
    CareCircleRequest,
    OtpRequest,
)


class CareAccountDeletion:
    """Deletes an account."""

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
