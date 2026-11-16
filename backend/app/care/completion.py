"""Finishing an accepted request: the patient's basics, and the circle."""

from datetime import date
from uuid import UUID

from app.circles.naming import OWN_NAME_DEFAULT
from app.errors import Forbidden, NotFound, ValidationFailed
from app.models import CareCircle


class CareCompletion:
    """Makes the circle of an accepted request."""

    def complete_creation(
        self,
        actor_id: UUID,
        request_id: UUID,
        birth_date: date | None,
        city: str | None,
        latitude: float | None = None,
        longitude: float | None = None,
        *,
        name: str | None = None,
        time_zone: str | None = None,
    ) -> CareCircle:
        """Activate only the accepted request owned by this patient.

        `name` is the patient's own name for the circle; only they see it.
        The sender and the other managers see «دائرة» and the patient's
        display name.
        """
        # Lock both accounts, then the request; only the patient it names may
        # finish it.
        request = self._get_creation_request(request_id)
        accounts = self._lock_accounts(
            actor_id, request.requested_by_account_id
        )
        request = self._get_creation_request(request_id, lock=True)
        account = accounts[actor_id]
        if request.patient_phone_number != account.phone_number:
            raise Forbidden("This request targets another account.")
        # Finished already (a retry): answer the same circle.
        if request.status == "completed":
            circle = self.session.get(CareCircle, request.care_circle_id)
            if circle is None:
                raise NotFound("The care circle does not exist.")
            return circle
        # Only a request this patient accepted, and only when they have no
        # circle yet.
        if (
            request.status != "accepted"
            or request.responded_by_account_id != actor_id
        ):
            raise ValidationFailed(
                "Patient consent is required.", code="consent_required"
            )
        self._require_no_patient(actor_id)
        # The patient's details from the request or their account; the sender
        # manages in the detailed mode, and the patient does too unless they
        # chose the simplified mode.
        birth_date, city = self._own_basics(account, birth_date, city)
        self._assign_app_mode(account, request.proposed_app_mode)
        requester = accounts[request.requested_by_account_id]
        self._assign_app_mode(requester, "detailed")
        managers = {request.requested_by_account_id}
        if account.app_mode == "detailed":
            managers.add(actor_id)
        # Make the circle under the patient's own name for it, and close the
        # request.
        own_name = (name or "").strip() or OWN_NAME_DEFAULT
        circle = self._create_circle(
            own_name,
            birth_date,
            city,
            managers,
            patient_account=account,
            leader=request.requested_by_account_id,
            latitude=latitude,
            longitude=longitude,
            time_zone=time_zone,
        )
        request.status = "completed"
        request.care_circle_id = circle.id
        request.completed_at = self.now
        self.session.flush()
        return circle
