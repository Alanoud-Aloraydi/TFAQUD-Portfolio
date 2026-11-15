"""Cancelling or resending a pending invitation."""

from uuid import UUID

from app.errors import NotFound, ValidationFailed
from app.models import CareCircleInvitation


class CareInvitationChanges:
    """Cancels and resends invitations."""

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
