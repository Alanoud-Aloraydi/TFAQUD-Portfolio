"""Who may do what in a circle: a finished profile, one patient circle,
a manager, the leader, a member."""

from uuid import UUID

from sqlalchemy import select

from app.circles.leader import leader_id
from app.errors import Forbidden, ValidationFailed
from app.models import Account, CareCircle, CareCircleManager


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
