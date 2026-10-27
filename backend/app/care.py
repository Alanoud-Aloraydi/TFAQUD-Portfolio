"""Atomic care workflows executed within caller-owned transactions."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import delete, select, update
from sqlalchemy.orm import Session

from app.errors import Forbidden, NotFound, ValidationFailed
from app.models import Account, CareCircle, CareCircleCreationRequest
from app.models import CareCircleManager, CareCircleManagerInvitation, Patient


class CareService:
    """Coordinate the six core entities using account-before-circle locks."""

    def __init__(self, session: Session, now: datetime):
        """Bind operations to a session and a consistent operation time."""
        self.session = session
        self.now = now

    def _lock_accounts(self, *account_ids: UUID) -> dict[UUID, Account]:
        """Lock accounts in stable order and refresh previously read values."""
        accounts = self.session.scalars(
            select(Account)
            .where(Account.id.in_(set(account_ids)))
            .order_by(Account.id)
            .with_for_update()
            .execution_options(populate_existing=True)
        ).all()
        if len(accounts) != len(set(account_ids)):
            raise NotFound("An account does not exist.")
        return {account.id: account for account in accounts}

    def _require_complete_profile(self, account: Account) -> None:
        """Require completed onboarding before participating in care."""
        if (
            not account.first_name
            or not account.last_name
            or not account.display_name
        ):
            raise ValidationFailed(
                "Complete the account profile first.",
                code="profile_incomplete",
            )

    def _assign_app_mode(self, account: Account, mode: str) -> None:
        """Assign a mode once; never overwrite an established choice."""
        self._require_complete_profile(account)
        if mode not in {"detailed", "simplified"}:
            raise ValidationFailed(
                "Unknown account mode.", code="invalid_mode"
            )
        if account.app_mode not in {None, mode}:
            raise ValidationFailed(
                "The account mode cannot change.", code="mode_conflict"
            )
        account.app_mode = mode
        self.session.flush()

    def _require_no_patient(self, account_id: UUID) -> None:
        """Recheck patient uniqueness after acquiring the account lock."""
        patient_id = self.session.scalar(
            select(Patient.id).where(Patient.account_id == account_id)
        )
        if patient_id is not None:
            raise ValidationFailed(
                "This account already has a care circle.",
                code="already_has_circle",
            )

    def _lock_circle(self, circle_id: UUID) -> CareCircle:
        """Serialize lifecycle operations on an existing circle."""
        circle = self.session.get(
            CareCircle, circle_id, with_for_update=True, populate_existing=True
        )
        if circle is None:
            raise NotFound("The care circle does not exist.")
        return circle

    def _require_manager(self, actor_id: UUID, circle_id: UUID) -> None:
        """Require a current management membership in the given circle."""
        manager_id = self.session.scalar(
            select(CareCircleManager.id).where(
                CareCircleManager.account_id == actor_id,
                CareCircleManager.care_circle_id == circle_id,
            )
        )
        if manager_id is None:
            raise Forbidden("A current manager membership is required.")

    def _get_patient(self, circle_id: UUID) -> Patient:
        """Return the circle's patient or raise NotFound."""
        patient = self.session.scalar(
            select(Patient).where(Patient.care_circle_id == circle_id)
        )
        if patient is None:
            raise NotFound("The patient does not exist.")
        return patient

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

    def _remove_manager(self, actor_id: UUID, circle_id: UUID) -> None:
        """Remove only the actor's membership from a locked circle."""
        self.session.execute(
            delete(CareCircleManager).where(
                CareCircleManager.care_circle_id == circle_id,
                CareCircleManager.account_id == actor_id,
            )
        )

    def _get_creation_request(
        self, request_id: UUID, *, lock: bool = False
    ) -> CareCircleCreationRequest:
        """Refresh a creation request and reject a concurrently deleted row."""
        request = self.session.get(
            CareCircleCreationRequest,
            request_id,
            with_for_update=lock,
            populate_existing=True,
        )
        if request is None:
            raise NotFound("The creation request does not exist.")
        return request

    def _get_invitation(
        self, invitation_id: UUID, *, lock: bool = False
    ) -> CareCircleManagerInvitation:
        """Refresh an invitation and reject a missing row."""
        invitation = self.session.get(
            CareCircleManagerInvitation,
            invitation_id,
            with_for_update=lock,
            populate_existing=True,
        )
        if invitation is None:
            raise NotFound("The invitation does not exist.")
        return invitation

    def _check_patient_basics(self, birth_date: date, city: str) -> None:
        """Birth date and city are required for every patient."""
        if not city.strip():
            raise ValidationFailed(
                "The city cannot be blank.", code="invalid_city"
            )
        if birth_date > self.now.date():
            raise ValidationFailed(
                "The birth date cannot be in the future.",
                code="invalid_birth_date",
            )

    def _create_circle(
        self,
        name: str,
        birth_date: date,
        city: str,
        managers: set[UUID],
        patient_account: Account | None = None,
        first_name: str | None = None,
        last_name: str | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> CareCircle:
        """Build a complete circle before deferred constraints run."""
        if not name.strip():
            raise ValidationFailed(
                "The circle name cannot be blank.", code="invalid_circle_name"
            )
        self._check_patient_basics(birth_date, city)
        circle = CareCircle(name=name.strip())
        self.session.add(circle)
        self.session.flush()
        self.session.add(
            Patient(
                care_circle_id=circle.id,
                account_id=patient_account.id if patient_account else None,
                first_name=first_name,
                last_name=last_name,
                birth_date=birth_date,
                city=city.strip(),
                latitude=latitude,
                longitude=longitude,
            )
        )
        for manager_id in sorted(managers):
            self.session.add(
                CareCircleManager(
                    care_circle_id=circle.id, account_id=manager_id
                )
            )
        self.session.flush()
        if patient_account:
            self.session.execute(
                update(CareCircleCreationRequest)
                .where(
                    CareCircleCreationRequest.patient_phone_number
                    == patient_account.phone_number,
                    CareCircleCreationRequest.status.in_(
                        ["pending", "accepted"]
                    ),
                )
                .values(status="superseded")
            )
        return circle

    def create_self(
        self,
        actor_id: UUID,
        name: str,
        birth_date: date,
        city: str,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> CareCircle:
        """Create self-care with both patient identity and management."""
        account = self._lock_accounts(actor_id)[actor_id]
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
        )

    def create_without_account(
        self,
        actor_id: UUID,
        name: str,
        first_name: str,
        last_name: str,
        birth_date: date,
        city: str,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> CareCircle:
        """Create a care circle for a patient without an account."""
        account = self._lock_accounts(actor_id)[actor_id]
        self._assign_app_mode(account, "detailed")
        if not first_name.strip() or not last_name.strip():
            raise ValidationFailed(
                "Both patient names are required.",
                code="patient_name_required",
            )
        return self._create_circle(
            name,
            birth_date,
            city,
            {actor_id},
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            latitude=latitude,
            longitude=longitude,
        )

    def request_creation(
        self, actor_id: UUID, phone: str, label: str, mode: str
    ) -> CareCircleCreationRequest:
        """Persist a pending request without allocating a circle."""
        target = self.session.scalar(
            select(Account).where(Account.phone_number == phone)
        )
        account_ids = [actor_id] + ([target.id] if target else [])
        account = self._lock_accounts(*account_ids)[actor_id]
        self._assign_app_mode(account, "detailed")
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
            select(CareCircleCreationRequest).where(
                CareCircleCreationRequest.requested_by_account_id == actor_id,
                CareCircleCreationRequest.patient_phone_number == phone,
                CareCircleCreationRequest.status.in_(["pending", "accepted"]),
            )
        )
        if existing:
            return existing
        request = CareCircleCreationRequest(
            requested_by_account_id=actor_id,
            patient_phone_number=phone,
            proposed_circle_label=label,
            proposed_app_mode=mode,
        )
        self.session.add(request)
        self.session.flush()
        return request

    def respond_creation(
        self, actor_id: UUID, request_id: UUID, accept: bool
    ) -> CareCircleCreationRequest:
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
                select(CareCircleCreationRequest.id).where(
                    CareCircleCreationRequest.responded_by_account_id
                    == actor_id,
                    CareCircleCreationRequest.status == "accepted",
                )
            )
            if other:
                raise ValidationFailed(
                    "Complete or cancel accepted care.",
                    code="accepted_request_exists",
                )
            self._assign_app_mode(account, request.proposed_app_mode)
        request.status = desired
        request.responded_by_account_id = actor_id
        request.responded_at = self.now
        self.session.flush()
        return request

    def complete_creation(
        self,
        actor_id: UUID,
        request_id: UUID,
        birth_date: date,
        city: str,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> CareCircle:
        """Activate only the accepted request owned by this patient."""
        request = self._get_creation_request(request_id)
        accounts = self._lock_accounts(
            actor_id, request.requested_by_account_id
        )
        request = self._get_creation_request(request_id, lock=True)
        account = accounts[actor_id]
        if request.patient_phone_number != account.phone_number:
            raise Forbidden("This request targets another account.")
        if request.status == "completed":
            circle = self.session.get(CareCircle, request.care_circle_id)
            if circle is None:
                raise NotFound("The care circle does not exist.")
            return circle
        if (
            request.status != "accepted"
            or request.responded_by_account_id != actor_id
        ):
            raise ValidationFailed(
                "Patient consent is required.", code="consent_required"
            )
        self._require_no_patient(actor_id)
        self._assign_app_mode(account, request.proposed_app_mode)
        requester = accounts[request.requested_by_account_id]
        self._assign_app_mode(requester, "detailed")
        managers = {request.requested_by_account_id}
        if account.app_mode == "detailed":
            managers.add(actor_id)
        name = f"{request.proposed_circle_label} {account.first_name}"
        circle = self._create_circle(
            name,
            birth_date,
            city,
            managers,
            patient_account=account,
            latitude=latitude,
            longitude=longitude,
        )
        request.status = "completed"
        request.care_circle_id = circle.id
        request.completed_at = self.now
        self.session.flush()
        return circle

    def cancel_creation(self, actor_id: UUID, request_id: UUID) -> None:
        """Allow the requester or verified patient to cancel pending care."""
        account = self._lock_accounts(actor_id)[actor_id]
        request = self._get_creation_request(request_id, lock=True)
        if (
            request.requested_by_account_id != actor_id
            and request.patient_phone_number != account.phone_number
        ):
            raise Forbidden("This request belongs to another account.")
        if request.status == "canceled":
            return
        if request.status not in {"pending", "accepted"}:
            raise ValidationFailed(
                "Only incomplete requests can be canceled.",
                code="request_not_cancelable",
            )
        request.status = "canceled"

    def invite_manager(
        self, actor_id: UUID, circle_id: UUID, phone: str
    ) -> CareCircleManagerInvitation:
        """Create or resend a pending invitation under the circle lock."""
        account = self._lock_accounts(actor_id)[actor_id]
        self._lock_circle(circle_id)
        self._require_manager(actor_id, circle_id)
        if phone == account.phone_number:
            raise ValidationFailed(
                "Self-invitations are not allowed.", code="self_invitation"
            )
        existing_manager = self.session.scalar(
            select(Account.id)
            .join(
                CareCircleManager, CareCircleManager.account_id == Account.id
            )
            .where(
                Account.phone_number == phone,
                CareCircleManager.care_circle_id == circle_id,
            )
        )
        if existing_manager:
            raise ValidationFailed(
                "The account already manages this circle.",
                code="already_manager",
            )
        invitation = self.session.scalar(
            select(CareCircleManagerInvitation).where(
                CareCircleManagerInvitation.care_circle_id == circle_id,
                CareCircleManagerInvitation.invitee_phone_number == phone,
                CareCircleManagerInvitation.status == "pending",
            )
        )
        if invitation:
            invitation.last_sent_at = self.now
        else:
            invitation = CareCircleManagerInvitation(
                care_circle_id=circle_id,
                invited_by_account_id=actor_id,
                invitee_phone_number=phone,
                last_sent_at=self.now,
            )
            self.session.add(invitation)
        self.session.flush()
        return invitation

    def respond_invitation(
        self, actor_id: UUID, invitation_id: UUID, accept: bool
    ) -> CareCircleManagerInvitation:
        """Accept or decline only an invitation to the actor's phone."""
        account = self._lock_accounts(actor_id)[actor_id]
        self._require_complete_profile(account)
        invitation = self._get_invitation(invitation_id)
        self._lock_circle(invitation.care_circle_id)
        invitation = self._get_invitation(invitation_id, lock=True)
        if invitation.invitee_phone_number != account.phone_number:
            raise Forbidden("This invitation targets another account.")
        desired = "accepted" if accept else "declined"
        if invitation.status == desired:
            return invitation
        if invitation.status != "pending":
            raise ValidationFailed(
                "The invitation is no longer pending.",
                code="invitation_not_pending",
            )
        if accept:
            self._assign_app_mode(account, "detailed")
            self.session.add(
                CareCircleManager(
                    account_id=actor_id,
                    care_circle_id=invitation.care_circle_id,
                )
            )
        invitation.status = desired
        invitation.responded_by_account_id = actor_id
        invitation.responded_at = self.now
        self.session.flush()
        return invitation

    def cancel_invitation(
        self,
        actor_id: UUID,
        invitation_id: UUID,
        circle_id: UUID | None = None,
    ) -> None:
        """Let any current manager cancel a still-pending invitation.

        When `circle_id` is given (the endpoint passes the circle in its URL),
        an invitation of another circle is reported as not found.
        """
        self._lock_accounts(actor_id)
        invitation = self._get_invitation(invitation_id)
        self._check_invitation_circle(invitation, circle_id)
        self._lock_circle(invitation.care_circle_id)
        self._require_manager(actor_id, invitation.care_circle_id)
        invitation = self._get_invitation(invitation_id, lock=True)
        if invitation.status == "canceled":
            return
        if invitation.status != "pending":
            raise ValidationFailed(
                "Only pending invitations can be canceled.",
                code="invitation_not_cancelable",
            )
        invitation.status = "canceled"

    def resend_invitation(
        self, actor_id: UUID, circle_id: UUID, invitation_id: UUID
    ) -> CareCircleManagerInvitation:
        """Mark a pending invitation as sent again, from its own circle."""
        self._lock_accounts(actor_id)
        self._lock_circle(circle_id)
        self._require_manager(actor_id, circle_id)
        invitation = self._get_invitation(invitation_id, lock=True)
        self._check_invitation_circle(invitation, circle_id)
        if invitation.status != "pending":
            raise ValidationFailed(
                "Only pending invitations can be sent again.",
                code="invitation_not_pending",
            )
        invitation.last_sent_at = self.now
        self.session.flush()
        return invitation

    @staticmethod
    def _check_invitation_circle(
        invitation: CareCircleManagerInvitation, circle_id: UUID | None
    ) -> None:
        """An invitation is only reachable through its own circle."""
        if circle_id is not None and invitation.care_circle_id != circle_id:
            raise NotFound("The invitation does not exist.")

    def leave_circle(
        self, actor_id: UUID, circle_id: UUID, confirm_delete: bool = False
    ) -> None:
        """Require explicit deletion when the last manager leaves."""
        self._lock_accounts(actor_id)
        circle = self._lock_circle(circle_id)
        self._require_manager(actor_id, circle_id)
        patient = self._get_patient(circle_id)
        is_patient = patient.account_id == actor_id
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
        """Allow a current manager to rename the shared circle."""
        self._lock_accounts(actor_id)
        circle = self._lock_circle(circle_id)
        self._require_manager(actor_id, circle_id)
        if not name.strip():
            raise ValidationFailed(
                "The circle name cannot be blank.", code="invalid_circle_name"
            )
        circle.name = name.strip()

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
    ) -> Patient:
        """Let managers and the linked patient edit basic medical identity."""
        patient = self._get_patient(circle_id)
        account_ids = {actor_id}
        if patient.account_id is not None:
            account_ids.add(patient.account_id)
        account = self._lock_accounts(*account_ids)[actor_id]
        self._require_complete_profile(account)
        self._lock_circle(circle_id)
        self.session.refresh(patient)
        if patient.account_id != actor_id:
            self._require_manager(actor_id, circle_id)
        self._check_patient_basics(birth_date, city)
        if patient.account_id is not None:
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
            patient.first_name = first_name.strip()
            patient.last_name = last_name.strip()
        patient.birth_date = birth_date
        patient.city = city.strip()
        patient.latitude = latitude
        patient.longitude = longitude
        self.session.flush()
        return patient

    def delete_circle(
        self, actor_id: UUID, circle_id: UUID, confirm: bool = False
    ) -> None:
        """Honor patient control, or explicit last-manager departure."""
        self._lock_accounts(actor_id)
        circle = self._lock_circle(circle_id)
        patient = self._get_patient(circle_id)
        if patient.account_id != actor_id:
            self._require_manager(actor_id, circle_id)
            if self._has_other_manager(actor_id, circle_id):
                raise Forbidden("Only the patient controls this deletion.")
        if not confirm:
            raise ValidationFailed(
                "Explicit circle deletion is required.",
                code="confirmation_required",
            )
        self.session.delete(circle)

    def delete_account(
        self,
        actor_id: UUID,
        patient_choice: str | None = None,
        delete_last_managed_circles: bool = False,
    ) -> None:
        """Resolve patient ownership and every membership before deletion."""
        account = self._lock_accounts(actor_id)[actor_id]
        patient = self.session.scalar(
            select(Patient).where(Patient.account_id == actor_id)
        )
        circle_ids = set(
            self.session.scalars(
                select(CareCircleManager.care_circle_id).where(
                    CareCircleManager.account_id == actor_id
                )
            )
        )
        if patient:
            circle_ids.add(patient.care_circle_id)
            if patient_choice not in {"delete", "continue"}:
                raise ValidationFailed(
                    "Choose deletion or continued care.",
                    code="patient_choice_required",
                )
        for circle_id in sorted(circle_ids):
            self._resolve_account_circle(
                account,
                patient,
                circle_id,
                patient_choice,
                delete_last_managed_circles,
            )
        self.session.execute(
            update(CareCircleCreationRequest)
            .where(
                CareCircleCreationRequest.responded_by_account_id == actor_id,
                CareCircleCreationRequest.status == "accepted",
            )
            .values(status="canceled")
        )
        self.session.delete(account)
        self.session.flush()

    def _resolve_account_circle(
        self,
        account: Account,
        patient: Patient | None,
        circle_id: UUID,
        patient_choice: str | None,
        delete_last_managed_circles: bool,
    ) -> None:
        """Resolve one locked circle before deleting its account."""
        circle = self._lock_circle(circle_id)
        own_circle = (
            patient is not None and patient.care_circle_id == circle_id
        )
        if own_circle and patient_choice == "delete":
            self.session.delete(circle)
            self.session.flush()
            return
        if not self._has_other_manager(account.id, circle_id):
            if own_circle or not delete_last_managed_circles:
                raise ValidationFailed(
                    "Another manager must remain.", code="last_manager"
                )
            self.session.delete(circle)
            self.session.flush()
            return
        if own_circle:
            patient.first_name = account.first_name
            patient.last_name = account.last_name
            patient.account_id = None
            self.session.flush()
        self._remove_manager(account.id, circle_id)
