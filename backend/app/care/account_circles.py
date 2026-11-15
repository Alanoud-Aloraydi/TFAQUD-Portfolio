"""What happens to one circle when an account in it is deleted."""

from uuid import UUID

from app.errors import ValidationFailed
from app.models import Account, CareCircle


class CareAccountCircles:
    """Resolves a circle of a deleted account."""

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
