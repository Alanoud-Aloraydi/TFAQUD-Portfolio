"""A request to care for a patient who has an account: asking and
cancelling, the patient's answer (consent), and finishing an accepted
request into a circle."""

from datetime import date
from uuid import UUID

from sqlalchemy import select

from app.circles.naming import OWN_NAME_DEFAULT
from app.errors import Forbidden, NotFound, ValidationFailed
from app.models import Account, CareCircle, CareCircleRequest


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

    # Records the patient's answer.
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

    # Makes the circle of an accepted request.
    def complete_creation(
        self,
        actor_id: UUID,
        request_id: UUID,
        birth_date: date | None,
        city: str | None,
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
            time_zone=time_zone,
            completing=request.id,
        )
        request.status = "completed"
        request.care_circle_id = circle.id
        request.completed_at = self.now
        self.session.flush()
        return circle
