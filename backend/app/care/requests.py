"""A request to care for a patient with an account: asking, and
cancelling."""

from uuid import UUID

from sqlalchemy import select

from app.errors import Forbidden, ValidationFailed
from app.models import Account, CareCircleRequest


class CareRequests:
    """Sends and cancels circle requests."""

    def request_creation(
        self, actor_id: UUID, phone: str, mode: str
    ) -> CareCircleRequest:
        """Persist a pending request without allocating a circle; the
        patient names the circle when they complete the request."""
        target = self.session.scalar(
            select(Account).where(Account.phone_number == phone)
        )
        account_ids = [actor_id] + ([target.id] if target else [])
        account = self._lock_accounts(*account_ids)[actor_id]
        # The mode used to be assigned here, and that assignment was also
        # what checked the profile; the check stays without it.
        self._require_complete_profile(account)
        # Not yet: nothing is created here, and `CircleAppMode.parse` already
        # treats a null mode as detailed for routing, so this account's own
        # mode stays undetermined until a circle actually exists for it
        # (`complete_creation` sets it there, the same as `create_self` and
        # `create_without_account` do at their own moment of creation).
        if phone == account.phone_number:
            raise ValidationFailed(
                "You cannot request a circle for your own number.",
                code="self_request",
            )
        if mode not in {"detailed", "simplified"}:
            raise ValidationFailed(
                "The proposed mode is not valid.", code="invalid_mode"
            )
        if target:
            self._require_no_patient(target.id)
        existing = self.session.scalar(
            select(CareCircleRequest).where(
                CareCircleRequest.requested_by_account_id == actor_id,
                CareCircleRequest.patient_phone_number == phone,
                CareCircleRequest.status.in_(["pending", "accepted"]),
            )
        )
        if existing:
            return existing
        self._require_room_for_circle(actor_id)
        request = CareCircleRequest(
            requested_by_account_id=actor_id,
            patient_phone_number=phone,
            proposed_app_mode=mode,
        )
        self.session.add(request)
        self.session.flush()
        return request

    def cancel_creation(self, actor_id: UUID, request_id: UUID) -> None:
        """Allow the requester or verified patient to cancel pending care."""
        # Only its sender or the patient it names cancels it; cancelled already
        # changes nothing; a finished or declined one cannot be.
        account = self._lock_accounts(actor_id)[actor_id]
        request = self._get_creation_request(request_id, lock=True)
        if (
            request.requested_by_account_id != actor_id
            and request.patient_phone_number != account.phone_number
        ):
            raise Forbidden("This request belongs to another account.")
        if request.status == "cancelled":
            return
        if request.status not in {"pending", "accepted"}:
            raise ValidationFailed(
                "Only incomplete requests can be canceled.",
                code="request_not_cancelable",
            )
        request.status = "cancelled"
