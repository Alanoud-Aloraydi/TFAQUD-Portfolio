"""The patient's answer to a circle request."""

from uuid import UUID

from sqlalchemy import select

from app.errors import Forbidden, ValidationFailed
from app.models import CareCircleRequest


class CareConsent:
    """Records the patient's answer."""

    def respond_creation(
        self, actor_id: UUID, request_id: UUID, accept: bool
    ) -> CareCircleRequest:
        """Record verified patient consent, without creating a circle."""
        account = self._lock_accounts(actor_id)[actor_id]
        self._require_complete_profile(account)
        request = self._get_creation_request(request_id, lock=True)
        if request.patient_phone_number != account.phone_number:
            raise Forbidden("This request targets another account.")
        desired = "accepted" if accept else "declined"
        if request.status == desired:
            return request
        if request.status != "pending":
            raise ValidationFailed(
                "The request is no longer pending.",
                code="request_not_pending",
            )
        if accept:
            self._require_no_patient(actor_id)
            other = self.session.scalar(
                select(CareCircleRequest.id).where(
                    CareCircleRequest.responded_by_account_id == actor_id,
                    CareCircleRequest.status == "accepted",
                )
            )
            if other:
                raise ValidationFailed(
                    "Complete or cancel accepted care.",
                    code="accepted_request_exists",
                )
            self._require_room_for_circle(actor_id)
            # Not yet: the mode is only committed once the circle actually
            # exists (complete_creation). Committing it here would strand
            # the account on an abandoned or canceled request, since
            # cancel_creation never clears it, blocking every later request
            # proposing a different mode.
        request.status = desired
        request.responded_by_account_id = actor_id
        request.responded_at = self.now
        self.session.flush()
        return request
