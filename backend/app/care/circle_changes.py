"""Changing a circle that exists: the leader's changes to the members (what
each may edit, handing the lead over, removing one), leaving, renaming and
deleting it, and editing the patient's basic profile."""

from datetime import date
from uuid import UUID

from sqlalchemy import delete, select

from app.circles.leader import AREAS, patient_leads
from app.errors import Conflict, Forbidden, NotFound, ValidationFailed
from app.models import CareCircle, CareCircleManager


class CareCircleChanges:
    """Leaves, renames and deletes circles."""

    def leave_circle(
        self, actor_id: UUID, circle_id: UUID, confirm_delete: bool = False
    ) -> None:
        """Leave the circle; the patient or the last member must confirm
        its deletion."""
        self._lock_accounts(actor_id)
        circle = self._lock_circle(circle_id)
        # A member whose editing is paused may leave; the owner's removal
        # of them is not the only way out.
        self._require_membership(actor_id, circle_id)
        is_patient = circle.account_id == actor_id
        if is_patient or not self._has_other_manager(actor_id, circle_id):
            if not confirm_delete:
                raise ValidationFailed(
                    "Explicit circle deletion is required.",
                    code="confirmation_required",
                )
            self.session.delete(circle)
        else:
            self._remove_manager(actor_id, circle_id)

    def rename_circle(
        self, actor_id: UUID, circle_id: UUID, name: str
    ) -> None:
        """Whoever chooses the patient's picture names the circle: the
        patient with an account, for themself (the others see an automatic
        name, `app.circles.naming`), or, for a patient without one, its
        managers, for everyone."""
        self._lock_accounts(actor_id)
        circle = self._lock_circle(circle_id)
        if circle.account_id is None:
            self._require_manager(actor_id, circle_id)
        elif circle.account_id != actor_id:
            raise Forbidden(
                "Only the patient names this circle.",
                code="patient_names_circle",
            )
        if not name.strip():
            raise ValidationFailed(
                "The circle name cannot be blank.", code="invalid_circle_name"
            )
        circle.name = name.strip()

    def delete_circle(
        self, actor_id: UUID, circle_id: UUID, confirm: bool = False
    ) -> None:
        """Honor patient control, or explicit last-manager departure."""
        self._lock_accounts(actor_id)
        circle = self._lock_circle(circle_id)
        if circle.account_id != actor_id:
            self._require_manager(actor_id, circle_id)
            if self._has_other_manager(actor_id, circle_id):
                raise Forbidden("Only the patient controls this deletion.")
        if not confirm:
            raise ValidationFailed(
                "Explicit circle deletion is required.",
                code="confirmation_required",
            )
        self.session.delete(circle)

    def _remove_manager(self, actor_id: UUID, circle_id: UUID) -> None:
        """Remove only the actor's membership from a locked circle."""
        self.session.execute(
            delete(CareCircleManager).where(
                CareCircleManager.care_circle_id == circle_id,
                CareCircleManager.account_id == actor_id,
            )
        )

    def _has_other_manager(self, actor_id: UUID, circle_id: UUID) -> bool:
        """Check for another manager while the circle is locked."""
        return self.session.scalar(
            select(
                select(CareCircleManager.id)
                .where(
                    CareCircleManager.care_circle_id == circle_id,
                    CareCircleManager.account_id != actor_id,
                )
                .exists()
            )
        )

    # Changes the members of a circle.
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

    # Edits the patient's profile.
    def update_patient_profile(
        self,
        actor_id: UUID,
        circle_id: UUID,
        birth_date: date,
        city: str,
        first_name: str | None = None,
        last_name: str | None = None,
        time_zone: str | None = None,
    ) -> CareCircle:
        """Let managers and the linked patient edit basic medical identity.

        `time_zone` left out keeps the saved zone (see `_zone_for`)."""
        # Lock the asker and the patient's account, then the circle; the
        # patient edits their own details, anyone else must be a manager.
        circle = self._get_circle(circle_id)
        account_ids = {actor_id}
        if circle.account_id is not None:
            account_ids.add(circle.account_id)
        accounts = self._lock_accounts(*account_ids)
        self._require_complete_profile(accounts[actor_id])
        circle = self._lock_circle(circle_id)
        if circle.account_id != actor_id:
            self._require_manager(actor_id, circle_id)
        # A patient with an account keeps the account's names; one without an
        # account needs both names here.
        if circle.account_id is not None:
            if first_name is not None or last_name is not None:
                raise ValidationFailed(
                    "Linked patient names use the account.",
                    code="linked_patient_name",
                )
        else:
            if not first_name or not first_name.strip():
                raise ValidationFailed(
                    "Both patient names are required.",
                    code="patient_name_required",
                )
            if not last_name or not last_name.strip():
                raise ValidationFailed(
                    "Both patient names are required.",
                    code="patient_name_required",
                )
            circle.first_name = first_name.strip()
            circle.last_name = last_name.strip()
        # Then the zone and the optional point on the circle, and the birth
        # date and city where the patient keeps them, checked together.
        circle.time_zone = self._zone_for(time_zone, circle.time_zone)
        self._check_patient_basics(circle, birth_date, city)
        holder = (
            accounts[circle.account_id]
            if circle.account_id is not None else circle
        )
        holder.birth_date = birth_date
        holder.city = city.strip()
        self.session.flush()
        return circle
