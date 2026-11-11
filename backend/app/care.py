"""Atomic care workflows executed within caller-owned transactions."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import delete, select, update
from sqlalchemy.orm import Session

from app.clock import DEFAULT_ZONE, is_zone, patient_today
from app.errors import Forbidden, NotFound, ValidationFailed
from app.circles.naming import OWN_NAME_DEFAULT
from app.models import Account, CareCircle, CareCircleInvitation
from app.models import CareCircleManager, CareCircleRequest, OtpRequest


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
        circle_id = self.session.scalar(
            select(CareCircle.id).where(CareCircle.account_id == account_id)
        )
        if circle_id is not None:
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
                CareCircleManager.can_edit.is_(True),
            )
        )
        if manager_id is None:
            raise Forbidden("A current manager membership is required.")

    def _require_membership(self, actor_id: UUID, circle_id: UUID) -> None:
        """Require any membership, including one whose editing is paused."""
        member_id = self.session.scalar(
            select(CareCircleManager.id).where(
                CareCircleManager.account_id == actor_id,
                CareCircleManager.care_circle_id == circle_id,
            )
        )
        if member_id is None:
            raise Forbidden("A circle membership is required.")

    def _get_circle(self, circle_id: UUID) -> CareCircle:
        """Return the circle (which is its patient) or raise NotFound."""
        circle = self.session.get(CareCircle, circle_id)
        if circle is None:
            raise NotFound("The care circle does not exist.")
        return circle

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

    def update_member_access(
        self, actor_id: UUID, circle_id: UUID, member_id: UUID, can_edit: bool
    ) -> None:
        """Let only the detailed patient pause or restore another member."""
        self._lock_accounts(actor_id, member_id)
        circle = self._lock_circle(circle_id)
        actor = self.session.get(Account, actor_id)
        if circle.account_id != actor_id or actor.app_mode != "detailed":
            raise Forbidden("Only the detailed circle owner manages access.")
        if member_id == actor_id:
            raise ValidationFailed(
                "The owner access cannot be changed.", code="circle_owner"
            )
        membership = self.session.scalar(
            select(CareCircleManager).where(
                CareCircleManager.care_circle_id == circle_id,
                CareCircleManager.account_id == member_id,
            ).with_for_update()
        )
        if membership is None:
            raise NotFound("The circle member does not exist.")
        membership.can_edit = can_edit

    def remove_member(
        self, actor_id: UUID, circle_id: UUID, member_id: UUID
    ) -> None:
        """Let only the detailed patient remove another circle member."""
        self._lock_accounts(actor_id, member_id)
        circle = self._lock_circle(circle_id)
        actor = self.session.get(Account, actor_id)
        if circle.account_id != actor_id or actor.app_mode != "detailed":
            raise Forbidden("Only the detailed circle owner removes members.")
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

    def _get_creation_request(
        self, request_id: UUID, *, lock: bool = False
    ) -> CareCircleRequest:
        """Refresh a circle request and reject a concurrently deleted row."""
        request = self.session.get(
            CareCircleRequest,
            request_id,
            with_for_update=lock,
            populate_existing=True,
        )
        if request is None:
            raise NotFound("The circle request does not exist.")
        return request

    def _get_invitation(
        self, invitation_id: UUID, *, lock: bool = False
    ) -> CareCircleInvitation:
        """Refresh an invitation and reject a missing row."""
        invitation = self.session.get(
            CareCircleInvitation,
            invitation_id,
            with_for_update=lock,
            populate_existing=True,
        )
        if invitation is None:
            raise NotFound("The invitation does not exist.")
        return invitation

    def _check_patient_basics(
        self, circle: CareCircle, birth_date: date, city: str
    ) -> None:
        """Birth date, city and zone are required for every patient.

        Runs on the values as they will be saved (on the circle, or on the
        patient's account): the birth date is checked against the day in
        the patient's own zone, as the app's date sheet counts it there."""
        if not city.strip():
            raise ValidationFailed(
                "The city cannot be blank.", code="invalid_city"
            )
        if not is_zone(circle.time_zone):
            raise ValidationFailed(
                "The time zone is not a known IANA zone.",
                code="invalid_time_zone",
            )
        if birth_date > patient_today(circle, self.now):
            raise ValidationFailed(
                "The birth date cannot be in the future.",
                code="invalid_birth_date",
            )

    @staticmethod
    def _zone_for(time_zone: str | None, current: str | None = None) -> str:
        """The patient's zone: the one sent, else the one saved, else
        `DEFAULT_ZONE`.

        The app sends the zone with every city: Saudi Arabia's for a city
        of its Saudi list, the phone's for a city typed by hand, and the
        person can change it later. An app older than zones sends none and
        offers only the Saudi list, so its patients live by DEFAULT_ZONE."""
        return time_zone or current or DEFAULT_ZONE

    @staticmethod
    def _own_basics(
        account: Account, birth_date: date | None, city: str | None
    ) -> tuple[date, str]:
        """The patient's birth date and city when the patient is the caller.

        What the request sends wins; what it leaves out comes from the
        account (onboarding saves both). An account made before onboarding
        asked for them has neither, and then the request must send them.
        """
        birth_date = birth_date or account.birth_date
        city = city or account.city
        if birth_date is None:
            raise ValidationFailed(
                "Add your birth date first.", code="birth_date_required"
            )
        if city is None:
            raise ValidationFailed(
                "Add your city first.", code="city_required"
            )
        return birth_date, city

    def _create_circle(
        self,
        name: str | None,
        birth_date: date,
        city: str,
        managers: set[UUID],
        patient_account: Account | None = None,
        first_name: str | None = None,
        last_name: str | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
        time_zone: str | None = None,
    ) -> CareCircle:
        """Build a complete circle before deferred constraints run.

        A patient with an account keeps the birth date and city on the
        account, and `name` is their own name for the circle; a patient
        without one keeps them on the circle, which has no name of its own.
        """
        if patient_account is not None and not (name or "").strip():
            raise ValidationFailed(
                "The circle name cannot be blank.", code="invalid_circle_name"
            )
        circle = CareCircle(
            name=name.strip() if patient_account is not None else None,
            account_id=patient_account.id if patient_account else None,
            time_zone=self._zone_for(time_zone),
            latitude=latitude,
            longitude=longitude,
        )
        self._check_patient_basics(circle, birth_date, city)
        if patient_account is not None:
            patient_account.birth_date = birth_date
            patient_account.city = city.strip()
        else:
            circle.first_name = first_name
            circle.last_name = last_name
            circle.birth_date = birth_date
            circle.city = city.strip()
        self.session.add(circle)
        self.session.flush()
        for manager_id in sorted(managers):
            self.session.add(
                CareCircleManager(
                    care_circle_id=circle.id, account_id=manager_id
                )
            )
        self.session.flush()
        # The patient has a circle now: their other open requests close.
        if patient_account:
            self.session.execute(
                update(CareCircleRequest)
                .where(
                    CareCircleRequest.patient_phone_number
                    == patient_account.phone_number,
                    CareCircleRequest.status.in_(
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
        request = CareCircleRequest(
            requested_by_account_id=actor_id,
            patient_phone_number=phone,
            proposed_app_mode=mode,
        )
        self.session.add(request)
        self.session.flush()
        return request

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
            latitude=latitude,
            longitude=longitude,
            time_zone=time_zone,
        )
        request.status = "completed"
        request.care_circle_id = circle.id
        request.completed_at = self.now
        self.session.flush()
        return circle

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

    def invite_manager(
        self, actor_id: UUID, circle_id: UUID, phone: str
    ) -> CareCircleInvitation:
        """Create or resend a pending invitation under the circle lock."""
        # Only a manager of the circle invites, and not their own number.
        account = self._lock_accounts(actor_id)[actor_id]
        self._lock_circle(circle_id)
        self._require_manager(actor_id, circle_id)
        if phone == account.phone_number:
            raise ValidationFailed(
                "Self-invitations are not allowed.", code="self_invitation"
            )
        # Someone who manages the circle already is not invited again.
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
        # A pending invitation to the same number is sent again, not made
        # twice.
        invitation = self.session.scalar(
            select(CareCircleInvitation).where(
                CareCircleInvitation.care_circle_id == circle_id,
                CareCircleInvitation.invitee_phone_number == phone,
                CareCircleInvitation.status == "pending",
            )
        )
        if invitation:
            invitation.last_sent_at = self.now
        else:
            invitation = CareCircleInvitation(
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
    ) -> CareCircleInvitation:
        """Accept or decline only an invitation to the actor's phone."""
        # Lock the account, the circle and the invitation; only the invited
        # number answers.
        account = self._lock_accounts(actor_id)[actor_id]
        self._require_complete_profile(account)
        invitation = self._get_invitation(invitation_id)
        self._lock_circle(invitation.care_circle_id)
        invitation = self._get_invitation(invitation_id, lock=True)
        if invitation.invitee_phone_number != account.phone_number:
            raise Forbidden("This invitation targets another account.")
        # The same answer again changes nothing; only a pending invitation is
        # answered.
        desired = "accepted" if accept else "declined"
        if invitation.status == desired:
            return invitation
        if invitation.status != "pending":
            raise ValidationFailed(
                "The invitation is no longer pending.",
                code="invitation_not_pending",
            )
        # Accepting makes the account a manager, in the detailed mode.
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
        if invitation.status == "cancelled":
            return
        if invitation.status != "pending":
            raise ValidationFailed(
                "Only pending invitations can be canceled.",
                code="invitation_not_cancelable",
            )
        invitation.status = "cancelled"

    def resend_invitation(
        self, actor_id: UUID, circle_id: UUID, invitation_id: UUID
    ) -> CareCircleInvitation:
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
        invitation: CareCircleInvitation, circle_id: UUID | None
    ) -> None:
        """An invitation is only reachable through its own circle."""
        if circle_id is not None and invitation.care_circle_id != circle_id:
            raise NotFound("The invitation does not exist.")

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

    def delete_account(
        self,
        actor_id: UUID,
        patient_choice: str | None = None,
        delete_last_managed_circles: bool = False,
    ) -> None:
        """Resolve patient ownership and every membership before deletion."""
        account = self._lock_accounts(actor_id)[actor_id]
        # Every circle the account is in: the one where it is the patient
        # (which needs its choice), and every one it manages.
        own = self.session.scalar(
            select(CareCircle).where(CareCircle.account_id == actor_id)
        )
        circle_ids = set(
            self.session.scalars(
                select(CareCircleManager.care_circle_id).where(
                    CareCircleManager.account_id == actor_id
                )
            )
        )
        if own:
            circle_ids.add(own.id)
            if patient_choice not in {"delete", "continue"}:
                raise ValidationFailed(
                    "Choose deletion or continued care.",
                    code="patient_choice_required",
                )
        # Settle each circle, in a fixed order so two deletions cannot lock
        # each other.
        for circle_id in sorted(circle_ids):
            self._resolve_account_circle(
                account,
                own,
                circle_id,
                patient_choice,
                delete_last_managed_circles,
            )
        # Nothing addressed to its phone number stays: the requests and
        # invitations still open for it, and its sign-in code requests
        # (with their sends). Then the account goes.
        self._forget_phone(account.phone_number)
        self.session.delete(account)
        self.session.flush()

    def _forget_phone(self, phone: str) -> None:
        """Delete what holds `phone` for someone who is leaving: the open
        requests and invitations to it, and its sign-in code requests."""
        self.session.execute(
            delete(CareCircleRequest).where(
                CareCircleRequest.patient_phone_number == phone,
                CareCircleRequest.status.in_(["pending", "accepted"]),
            )
        )
        self.session.execute(
            delete(CareCircleInvitation).where(
                CareCircleInvitation.invitee_phone_number == phone,
                CareCircleInvitation.status == "pending",
            )
        )
        self.session.execute(
            delete(OtpRequest).where(OtpRequest.phone_number == phone)
        )

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
