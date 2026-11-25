"""Inviting a manager to a circle: sending, sending again and cancelling,
and the invited person's answer."""

from uuid import UUID

from sqlalchemy import select

from app.errors import Forbidden, NotFound, ValidationFailed
from app.models import Account, CareCircleInvitation, CareCircleManager


class CareInvitations:
    """Sends invitations and records answers."""

    def invite_manager(
        self, actor_id: UUID, circle_id: UUID, phone: str
    ) -> CareCircleInvitation:
        """Create or resend a pending invitation under the circle lock."""
        # Only a manager of the circle invites, and not their own number.
        account = self._lock_accounts(actor_id)[actor_id]
        self._lock_circle(circle_id)
        self._require_manager(actor_id, circle_id)
        if phone == account.phone_number:
            raise ValidationFailed(
                "Self-invitations are not allowed.", code="self_invitation"
            )
        # Someone who manages the circle already is not invited again.
        existing_manager = self.session.scalar(
            select(Account.id)
            .join(
                CareCircleManager, CareCircleManager.account_id == Account.id
            )
            .where(
                Account.phone_number == phone,
                CareCircleManager.care_circle_id == circle_id,
            )
        )
        if existing_manager:
            raise ValidationFailed(
                "The account already manages this circle.",
                code="already_manager",
            )
        # A pending invitation to the same number is sent again, not made
        # twice.
        invitation = self.session.scalar(
            select(CareCircleInvitation).where(
                CareCircleInvitation.care_circle_id == circle_id,
                CareCircleInvitation.invitee_phone_number == phone,
                CareCircleInvitation.status == "pending",
            )
        )
        if invitation:
            invitation.last_sent_at = self.now
        else:
            invitation = CareCircleInvitation(
                care_circle_id=circle_id,
                invited_by_account_id=actor_id,
                invitee_phone_number=phone,
                last_sent_at=self.now,
            )
            self.session.add(invitation)
        self.session.flush()
        return invitation

    def respond_invitation(
        self, actor_id: UUID, invitation_id: UUID, accept: bool
    ) -> CareCircleInvitation:
        """Accept or decline only an invitation to the actor's phone."""
        # Lock the account, the circle and the invitation; only the invited
        # number answers.
        account = self._lock_accounts(actor_id)[actor_id]
        self._require_complete_profile(account)
        invitation = self._get_invitation(invitation_id)
        self._lock_circle(invitation.care_circle_id)
        invitation = self._get_invitation(invitation_id, lock=True)
        if invitation.invitee_phone_number != account.phone_number:
            raise Forbidden("This invitation targets another account.")
        # The same answer changes nothing; only a pending one is answered.
        desired = "accepted" if accept else "declined"
        if invitation.status == desired:
            return invitation
        if invitation.status != "pending":
            raise ValidationFailed(
                "The invitation is no longer pending.",
                code="invitation_not_pending",
            )
        # Accepting makes the account a manager, in the detailed mode.
        if accept:
            self._require_room_for_circle(actor_id)
            self._assign_app_mode(account, "detailed")
            self.session.add(
                CareCircleManager(
                    account_id=actor_id,
                    care_circle_id=invitation.care_circle_id,
                )
            )
        invitation.status = desired
        invitation.responded_by_account_id = actor_id
        invitation.responded_at = self.now
        self.session.flush()
        return invitation

    # Cancels and resends invitations.
    def cancel_invitation(
        self,
        actor_id: UUID,
        invitation_id: UUID,
        circle_id: UUID | None = None,
    ) -> None:
        """Let any current manager cancel a still-pending invitation.

        When `circle_id` is given (the endpoint passes the circle in its URL),
        an invitation of another circle is reported as not found.
        """
        self._lock_accounts(actor_id)
        invitation = self._get_invitation(invitation_id)
        self._check_invitation_circle(invitation, circle_id)
        self._lock_circle(invitation.care_circle_id)
        self._require_manager(actor_id, invitation.care_circle_id)
        invitation = self._get_invitation(invitation_id, lock=True)
        if invitation.status == "cancelled":
            return
        if invitation.status != "pending":
            raise ValidationFailed(
                "Only pending invitations can be canceled.",
                code="invitation_not_cancelable",
            )
        invitation.status = "cancelled"

    def resend_invitation(
        self, actor_id: UUID, circle_id: UUID, invitation_id: UUID
    ) -> CareCircleInvitation:
        """Mark a pending invitation as sent again, from its own circle."""
        self._lock_accounts(actor_id)
        self._lock_circle(circle_id)
        self._require_manager(actor_id, circle_id)
        invitation = self._get_invitation(invitation_id, lock=True)
        self._check_invitation_circle(invitation, circle_id)
        if invitation.status != "pending":
            raise ValidationFailed(
                "Only pending invitations can be sent again.",
                code="invitation_not_pending",
            )
        invitation.last_sent_at = self.now
        self.session.flush()
        return invitation

    @staticmethod
    def _check_invitation_circle(
        invitation: CareCircleInvitation, circle_id: UUID | None
    ) -> None:
        """An invitation is only reachable through its own circle."""
        if circle_id is not None and invitation.care_circle_id != circle_id:
            raise NotFound("The invitation does not exist.")
