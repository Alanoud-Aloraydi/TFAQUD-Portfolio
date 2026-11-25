"""The rules every care workflow checks, under locks: the accounts and the
circle it changes are locked and read again, and who may do what is
checked (a finished profile, one patient circle, a manager, the leader, a
member, at most MAX_CIRCLES circles per person)."""

from uuid import UUID

from sqlalchemy import and_, func, or_, select

from app.circles.leader import leader_id
from app.errors import Forbidden, NotFound, ValidationFailed
from app.models import (
    Account,
    CareCircle,
    CareCircleInvitation,
    CareCircleManager,
    CareCircleRequest,
)


# The circles a person can be in at once, counting the requests that may
# still become one.
MAX_CIRCLES = 6


class CareRules:
    """Refuses an actor who may not do the workflow."""

    def _require_complete_profile(self, account: Account) -> None:
        """Require completed onboarding before participating in care."""
        if (
            not account.first_name
            or not account.last_name
            or not account.display_name
        ):
            raise ValidationFailed(
                "Complete the account profile first.",
                code="profile_incomplete",
            )

    def _assign_app_mode(self, account: Account, mode: str) -> None:
        """Assign a mode once; never overwrite an established choice."""
        self._require_complete_profile(account)
        if mode not in {"detailed", "simplified"}:
            raise ValidationFailed(
                "Unknown account mode.", code="invalid_mode"
            )
        if account.app_mode not in {None, mode}:
            raise ValidationFailed(
                "The account mode cannot change.", code="mode_conflict"
            )
        account.app_mode = mode
        self.session.flush()

    def _require_no_patient(self, account_id: UUID) -> None:
        """Recheck patient uniqueness after acquiring the account lock."""
        circle_id = self.session.scalar(
            select(CareCircle.id).where(CareCircle.account_id == account_id)
        )
        if circle_id is not None:
            raise ValidationFailed(
                "This account already has a care circle.",
                code="already_has_circle",
            )

    def _require_manager(self, actor_id: UUID, circle_id: UUID) -> None:
        """Require a membership that edits something: one the leader lets
        edit nothing only reads (`app.circles.leader`)."""
        membership = self.session.scalar(
            select(CareCircleManager).where(
                CareCircleManager.account_id == actor_id,
                CareCircleManager.care_circle_id == circle_id,
            )
        )
        if membership is None or not (
            membership.can_edit_any or self._leads(actor_id, circle_id)
        ):
            raise Forbidden("A current manager membership is required.")

    def _leads(self, actor_id: UUID, circle_id: UUID) -> bool:
        """Whether the actor leads the circle now."""
        circle = self.session.get(CareCircle, circle_id)
        return circle is not None and leader_id(self.session, circle) == (
            actor_id
        )

    def _require_leader(self, actor_id: UUID, circle: CareCircle) -> None:
        """Only the circle's leader manages its members."""
        if leader_id(self.session, circle) != actor_id:
            raise Forbidden("Only the circle's leader manages its members.")

    def _require_membership(self, actor_id: UUID, circle_id: UUID) -> None:
        """Require any membership, including one whose editing is paused."""
        member_id = self.session.scalar(
            select(CareCircleManager.id).where(
                CareCircleManager.account_id == actor_id,
                CareCircleManager.care_circle_id == circle_id,
            )
        )
        if member_id is None:
            raise Forbidden("A circle membership is required.")

    # Locks rows in a stable order and reads them again.
    def _lock_accounts(self, *account_ids: UUID) -> dict[UUID, Account]:
        """Lock accounts in stable order and refresh previously read values."""
        accounts = self.session.scalars(
            select(Account)
            .where(Account.id.in_(set(account_ids)))
            .order_by(Account.id)
            .with_for_update()
            .execution_options(populate_existing=True)
        ).all()
        if len(accounts) != len(set(account_ids)):
            raise NotFound("An account does not exist.")
        return {account.id: account for account in accounts}

    def _lock_circle(self, circle_id: UUID) -> CareCircle:
        """Serialize lifecycle operations on an existing circle."""
        circle = self.session.get(
            CareCircle, circle_id, with_for_update=True, populate_existing=True
        )
        if circle is None:
            raise NotFound("The care circle does not exist.")
        return circle

    def _get_circle(self, circle_id: UUID) -> CareCircle:
        """Return the circle (which is its patient) or raise NotFound."""
        circle = self.session.get(CareCircle, circle_id)
        if circle is None:
            raise NotFound("The care circle does not exist.")
        return circle

    def _get_creation_request(
        self, request_id: UUID, *, lock: bool = False
    ) -> CareCircleRequest:
        """Refresh a circle request and reject a concurrently deleted row."""
        request = self.session.get(
            CareCircleRequest,
            request_id,
            with_for_update=lock,
            populate_existing=True,
        )
        if request is None:
            raise NotFound("The circle request does not exist.")
        return request

    def _get_invitation(
        self, invitation_id: UUID, *, lock: bool = False
    ) -> CareCircleInvitation:
        """Refresh an invitation and reject a missing row."""
        invitation = self.session.get(
            CareCircleInvitation,
            invitation_id,
            with_for_update=lock,
            populate_existing=True,
        )
        if invitation is None:
            raise NotFound("The invitation does not exist.")
        return invitation

    # Refuses a seventh circle.
    def _require_room_for_circle(self, account_id: UUID) -> None:
        """Count the circles the account manages or is the patient of, and
        the requests it sent or accepted that are still open; refuse when
        they already make MAX_CIRCLES. Call it after locking the account."""
        circles = set(
            self.session.scalars(
                select(CareCircleManager.care_circle_id).where(
                    CareCircleManager.account_id == account_id
                )
            )
        )
        circles.update(
            self.session.scalars(
                select(CareCircle.id).where(
                    CareCircle.account_id == account_id
                )
            )
        )
        waiting = self.session.scalar(
            select(func.count()).select_from(CareCircleRequest).where(
                or_(
                    and_(
                        CareCircleRequest.requested_by_account_id
                        == account_id,
                        CareCircleRequest.status.in_(["pending", "accepted"]),
                    ),
                    and_(
                        CareCircleRequest.responded_by_account_id
                        == account_id,
                        CareCircleRequest.status == "accepted",
                    ),
                )
            )
        )
        if len(circles) + (waiting or 0) >= MAX_CIRCLES:
            raise ValidationFailed(
                f"A person can be in at most {MAX_CIRCLES} circles.",
                code="too_many_circles",
            )
