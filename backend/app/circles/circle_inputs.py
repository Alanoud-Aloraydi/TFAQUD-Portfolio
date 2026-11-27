"""The bodies about the circle and its people: making it, its patient's
basics, renaming it, what each member edits, the lead, leaving, inviting,
asking and answering."""

from uuid import UUID

from pydantic import model_validator

from app.auth.inputs import Phone
from app.circles.inputs import (
    AppMode,
    CircleName,
    City,
    Flag,
    IsoDate,
    MedicalProfileInput,
    Name50,
    TimeZone,
)
from app.validation import Dto


class EditAreasInput(Dto):
    """What a member may edit, area by area; an area left out stays."""

    medications: Flag | None = None
    measurements: Flag | None = None
    appointments: Flag | None = None


class MemberAccessInput(Dto):
    """The leader's edit permissions for one member: per area
    (`edit_access`), or `can_edit` for all three at once (the app before
    the areas sends it)."""

    edit_access: EditAreasInput | None = None
    can_edit: Flag | None = None

    @model_validator(mode="after")
    def one_form(self):
        """Exactly one of the two."""
        if (self.edit_access is None) == (self.can_edit is None):
            raise ValueError("Send either edit_access or can_edit.")
        return self

    def areas(self) -> dict[str, bool]:
        """The areas to change, with their new value."""
        if self.can_edit is not None:
            return {
                area: self.can_edit
                for area in ("medications", "measurements", "appointments")
            }
        return self.edit_access.model_dump(exclude_none=True)


class LeaderInput(Dto):
    """The member the leader hands the circle to."""

    account_id: UUID


class LeaveCircleInput(Dto):
    """The body of leaving a circle; the last manager must also confirm its
    deletion.
    """

    confirm_delete: Flag = False


class InviteInput(Dto):
    """The body of inviting another manager by phone number."""

    invitee_phone_number: Phone


class RespondInput(Dto):
    """The body of answering a request or an invitation: accept or decline."""

    accept: Flag


class CircleRequestInput(Dto):
    """The body of asking a patient to make their circle."""

    patient_phone_number: Phone
    proposed_app_mode: AppMode


class _Place(Dto):
    """City and the city's IANA zone (left out by an app older than zones;
    see `CareService._zone_for`)."""

    city: City
    time_zone: TimeZone | None = None


class _PatientBasics(_Place):
    """A patient who is not the caller: city, birth date and medical
    profile.
    """

    birth_date: IsoDate
    medical_profile: MedicalProfileInput | None = None


class _OwnBasics(Dto):
    """The patient is the caller: a birth date or city left out is read
    from the account, where onboarding saved it."""

    birth_date: IsoDate | None = None
    city: City | None = None
    time_zone: TimeZone | None = None
    medical_profile: MedicalProfileInput | None = None


class CreateSelfCircleInput(_OwnBasics):
    """The body of creating one's own circle (the caller is the patient)."""

    name: CircleName


class CreateOfflineCircleInput(_PatientBasics):
    """The body of creating a circle for a patient without an account."""

    # Not used: the circle is named «دائرة» and the patient's first name.
    # An older app still sends it.
    name: CircleName | None = None
    patient_first_name: Name50
    patient_last_name: Name50


class CompleteRequestInput(_OwnBasics):
    """The body of the patient accepting a request to make their circle."""

    # The patient's own name for the circle; only they see it. An older app
    # sends none, and the circle is then «دائرتي».
    name: CircleName | None = None


class PatientUpdateInput(_Place):
    """The body of changing the patient's details."""

    birth_date: IsoDate
    first_name: Name50 | None = None
    last_name: Name50 | None = None


class RenameCircleInput(Dto):
    """The body of renaming a circle."""

    name: CircleName
