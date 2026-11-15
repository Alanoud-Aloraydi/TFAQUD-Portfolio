"""Editing the patient's basic medical profile."""

from datetime import date
from uuid import UUID

from app.errors import ValidationFailed
from app.models import CareCircle


class CarePatientProfile:
    """Edits the patient's profile."""

    def update_patient_profile(
        self,
        actor_id: UUID,
        circle_id: UUID,
        birth_date: date,
        city: str,
        first_name: str | None = None,
        last_name: str | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
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
        circle.latitude = latitude
        circle.longitude = longitude
        self._check_patient_basics(circle, birth_date, city)
        holder = (
            accounts[circle.account_id]
            if circle.account_id is not None else circle
        )
        holder.birth_date = birth_date
        holder.city = city.strip()
        self.session.flush()
        return circle
