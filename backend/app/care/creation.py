"""Making a circle at once: self-care, or for a patient without an
account."""

from datetime import date
from uuid import UUID

from app.errors import ValidationFailed
from app.models import CareCircle


class CareCreation:
    """Makes a circle at once."""

    def create_self(
        self,
        actor_id: UUID,
        name: str,
        birth_date: date | None,
        city: str | None,
        latitude: float | None = None,
        longitude: float | None = None,
        time_zone: str | None = None,
    ) -> CareCircle:
        """Create self-care with both patient identity and management."""
        account = self._lock_accounts(actor_id)[actor_id]
        birth_date, city = self._own_basics(account, birth_date, city)
        self._assign_app_mode(account, "detailed")
        self._require_no_patient(actor_id)
        return self._create_circle(
            name,
            birth_date,
            city,
            {actor_id},
            patient_account=account,
            latitude=latitude,
            longitude=longitude,
            time_zone=time_zone,
        )

    def create_without_account(
        self,
        actor_id: UUID,
        first_name: str,
        last_name: str,
        birth_date: date,
        city: str,
        latitude: float | None = None,
        longitude: float | None = None,
        time_zone: str | None = None,
    ) -> CareCircle:
        """Create a care circle for a patient without an account.

        Nobody chooses its name: everyone sees «دائرة» and the patient's
        first name (`app.circles.naming`), so the circle stores none.
        """
        # The asker manages in the detailed mode, and the patient needs both
        # names.
        account = self._lock_accounts(actor_id)[actor_id]
        self._assign_app_mode(account, "detailed")
        if not first_name.strip() or not last_name.strip():
            raise ValidationFailed(
                "Both patient names are required.",
                code="patient_name_required",
            )
        return self._create_circle(
            None,
            birth_date,
            city,
            {actor_id},
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            latitude=latitude,
            longitude=longitude,
            time_zone=time_zone,
        )
