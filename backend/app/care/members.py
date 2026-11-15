"""The leader's changes to the members: what each may edit, handing the
lead over, removing one."""

from uuid import UUID

from sqlalchemy import delete, select

from app.circles.leader import AREAS, patient_leads
from app.errors import Conflict, NotFound, ValidationFailed
from app.models import CareCircleManager


class CareMembers:
    """Changes the members of a circle."""

    def update_member_access(
        self,
        actor_id: UUID,
        circle_id: UUID,
        member_id: UUID,
        areas: dict[str, bool],
    ) -> None:
        """Let only the leader turn another member's editing of each area
        (`app.circles.leader.AREAS`) on or off; an area left out stays."""
        self._lock_accounts(actor_id, member_id)
        circle = self._lock_circle(circle_id)
        self._require_leader(actor_id, circle)
        if member_id == actor_id:
            raise ValidationFailed(
                "The leader always edits everything.", code="circle_owner"
            )
        membership = self._membership_for_update(circle_id, member_id)
        for area, allowed in areas.items():
            if area not in AREAS:
                raise ValidationFailed(
                    "Unknown area.", code="validation_error"
                )
            setattr(membership, f"can_edit_{area}", allowed)
        self.session.flush()

    def hand_over_leadership(
        self, actor_id: UUID, circle_id: UUID, member_id: UUID
    ) -> None:
        """Let the leader hand the circle to another member. A patient in
        the detailed mode always leads their own circle."""
        self._lock_accounts(actor_id, member_id)
        circle = self._lock_circle(circle_id)
        self._require_leader(actor_id, circle)
        if patient_leads(self.session, circle):
            raise Conflict(
                "The patient leads their own circle.", code="patient_leads"
            )
        if member_id == actor_id:
            return
        self._membership_for_update(circle_id, member_id)
        circle.leader_account_id = member_id
        self.session.flush()

    def _membership_for_update(
        self, circle_id: UUID, member_id: UUID
    ) -> CareCircleManager:
        membership = self.session.scalar(
            select(CareCircleManager).where(
                CareCircleManager.care_circle_id == circle_id,
                CareCircleManager.account_id == member_id,
            ).with_for_update()
        )
        if membership is None:
            raise NotFound("The circle member does not exist.")
        return membership

    def remove_member(
        self, actor_id: UUID, circle_id: UUID, member_id: UUID
    ) -> None:
        """Let only the leader remove another circle member; never the
        patient."""
        self._lock_accounts(actor_id, member_id)
        circle = self._lock_circle(circle_id)
        self._require_leader(actor_id, circle)
        if member_id == actor_id or member_id == circle.account_id:
            raise ValidationFailed(
                "The circle owner cannot be removed.", code="circle_owner"
            )
        removed = self.session.execute(
            delete(CareCircleManager).where(
                CareCircleManager.care_circle_id == circle_id,
                CareCircleManager.account_id == member_id,
            )
        )
        if removed.rowcount == 0:
            raise NotFound("The circle member does not exist.")
