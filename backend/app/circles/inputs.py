"""Request bodies for the circle endpoints (see app/validation.py)."""

import re
import unicodedata
from datetime import date
from typing import Annotated, Literal
from uuid import UUID

from pydantic import AfterValidator, BeforeValidator, Field, model_validator
from pydantic_core import PydanticCustomError

from app.auth.inputs import Phone
from app.medical import Allergies, Conditions, MedicalUpdate, UNSET
from app.models.medical import (
    BLOOD_TYPES,
    CONDITION_CODES,
    CONTACT_RELATIONS,
    FOOD_ALLERGY_CODES,
    MEDICATION_ALLERGY_CODES,
)
from app.validation import Dto

_ISO_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_OLDEST_BIRTH = date(1900, 1, 1)


def _one_line(value: str) -> str:
    """Refuse a text with a line break or another control character."""
    # Control characters (line breaks, tabs) are not valid in a name or city.
    if any(unicodedata.category(ch) == "Cc" for ch in value):
        raise PydanticCustomError(
            "invalid_text",
            "The text cannot contain line breaks or control characters.",
        )
    return value


def _text(max_length: int):
    """A text of 1 to `max_length` characters on one line."""
    # The DTO base removes surrounding spaces before these checks run.
    return Annotated[
        str,
        Field(min_length=1, max_length=max_length),
        AfterValidator(_one_line),
    ]


def _iso_date_only(value):
    """Accept a date only as "YYYY-MM-DD" text."""
    # Only "YYYY-MM-DD". Numbers and other formats are not dates here.
    if not isinstance(value, str) or not _ISO_DATE.fullmatch(value):
        raise PydanticCustomError(
            "invalid_date", "The date must be written as YYYY-MM-DD."
        )
    return value


Name50 = _text(50)
CircleName = _text(60)
City = _text(60)
# An IANA zone name such as "Europe/London"; CareService checks it is real.
TimeZone = _text(64)
OtherText = _text(100)
IsoDate = Annotated[
    date, BeforeValidator(_iso_date_only), Field(ge=_OLDEST_BIRTH)
]
Latitude = Annotated[
    float, Field(strict=True, ge=-90, le=90, allow_inf_nan=False)
]
Longitude = Annotated[
    float, Field(strict=True, ge=-180, le=180, allow_inf_nan=False)
]
Flag = Annotated[bool, Field(strict=True)]
AppMode = Literal["detailed", "simplified"]


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


# ---- medical profile --------------------------------------------------


class ConditionsInput(Dto):
    """The patient's conditions: none, or the listed codes plus optional words
    for «أخرى».
    """

    status: Literal["none", "listed"]
    codes: list[Literal[CONDITION_CODES]] = Field(
        default_factory=list, max_length=len(CONDITION_CODES)
    )
    other: OtherText | None = None


class AllergiesInput(Dto):
    """The patient's allergies: none, or the listed medication and food codes
    plus optional words for each «أخرى».
    """

    status: Literal["none", "listed"]
    medication: list[Literal[MEDICATION_ALLERGY_CODES]] = Field(
        default_factory=list, max_length=len(MEDICATION_ALLERGY_CODES)
    )
    other_medication: OtherText | None = None
    food: list[Literal[FOOD_ALLERGY_CODES]] = Field(
        default_factory=list, max_length=len(FOOD_ALLERGY_CODES)
    )
    other_food: OtherText | None = None


class MedicalProfileInput(Dto):
    """Parts that are left out stay as they are; null clears a part."""

    blood_type: Literal[BLOOD_TYPES] | None = None
    conditions: ConditionsInput | None = None
    allergies: AllergiesInput | None = None

    def to_update(self) -> MedicalUpdate:
        """What to change in the medical profile: only the parts the app sent
        (a part left out stays as it is).
        """
        # A part the app left out stays UNSET (unchanged); a part sent as null
        # is cleared.
        sent = self.model_fields_set
        conditions, allergies = UNSET, UNSET
        if "conditions" in sent:
            conditions = None
            if self.conditions is not None:
                conditions = Conditions(
                    self.conditions.status,
                    tuple(self.conditions.codes),
                    self.conditions.other,
                )
        if "allergies" in sent:
            allergies = None
            if self.allergies is not None:
                allergies = Allergies(
                    self.allergies.status,
                    tuple(self.allergies.medication),
                    self.allergies.other_medication,
                    tuple(self.allergies.food),
                    self.allergies.other_food,
                )
        return MedicalUpdate(
            blood_type=self.blood_type if "blood_type" in sent else UNSET,
            conditions=conditions,
            allergies=allergies,
        )


class EmergencyContactInput(Dto):
    """One emergency contact: name, relation and a Saudi mobile number."""

    name: Name50
    relation: Literal[CONTACT_RELATIONS]
    phone_number: Phone


# ---- circles and patients ----------------------------------------------


class _Point(Dto):
    """The optional point the app got from the phone's location."""

    latitude: Latitude | None = None
    longitude: Longitude | None = None

    @model_validator(mode="after")
    def _both_or_neither(self):
        """Refuse a latitude without a longitude, or the other way round."""
        if (self.latitude is None) != (self.longitude is None):
            raise PydanticCustomError(
                "incomplete_location",
                "Send both latitude and longitude, or neither.",
            )
        return self


class _Place(_Point):
    """City plus the optional point, and the city's IANA zone (left out by
    an app older than zones; see `CareService._zone_for`)."""

    city: City
    time_zone: TimeZone | None = None


class _PatientBasics(_Place):
    """A patient who is not the caller: city, birth date, optional point and
    medical profile.
    """

    birth_date: IsoDate
    medical_profile: MedicalProfileInput | None = None


class _OwnBasics(_Point):
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


class LeaveCircleInput(Dto):
    """The body of leaving a circle; the last manager must also confirm its
    deletion.
    """

    confirm_delete: Flag = False


# ---- requests and invitations --------------------------------------------


class CircleRequestInput(Dto):
    """The body of asking a patient to make their circle."""

    patient_phone_number: Phone
    proposed_app_mode: AppMode


class InviteInput(Dto):
    """The body of inviting another manager by phone number."""

    invitee_phone_number: Phone


class RespondInput(Dto):
    """The body of answering a request or an invitation: accept or decline."""

    accept: Flag


# ---- account ------------------------------------------------------------


class DeleteAccountInput(Dto):
    """The body of deleting one's account: a patient chooses whether their
    circle is deleted or its care continues, and the last manager of a circle
    confirms its deletion.
    """

    patient_choice: Literal["delete", "continue"] | None = None
    delete_last_managed_circles: Flag = False
