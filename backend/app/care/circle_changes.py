"""Leaving, renaming and deleting a circle."""

from uuid import UUID

from sqlalchemy import delete, select

from app.errors import Forbidden, ValidationFailed
from app.models import CareCircleManager


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
        """Only the patient with an account names the circle, for themself.

        The others see an automatic name (`app.circles.naming`), so a
        manager who is not the patient cannot change it.
        """
        # Only the circle's patient names it (the others see «دائرة» and the
        # patient's name), and not with a blank name.
        self._lock_accounts(actor_id)
        circle = self._lock_circle(circle_id)
        if circle.account_id is None or circle.account_id != actor_id:
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
