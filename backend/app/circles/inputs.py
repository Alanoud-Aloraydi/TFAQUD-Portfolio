"""Request bodies for the circle endpoints (see app/validation.py)."""

import re
import unicodedata
from datetime import date
from typing import Annotated, Literal

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
    # Control characters (line breaks, tabs) are not valid in a name or city.
    if any(unicodedata.category(ch) == "Cc" for ch in value):
        raise PydanticCustomError(
            "invalid_text",
            "The text cannot contain line breaks or control characters.",
        )
    return value


def _text(max_length: int):
    # The DTO base removes surrounding spaces before these checks run.
    return Annotated[
        str,
        Field(min_length=1, max_length=max_length),
        AfterValidator(_one_line),
    ]


def _iso_date_only(value):
    # Only "YYYY-MM-DD". Numbers and other formats are not dates here.
    if not isinstance(value, str) or not _ISO_DATE.fullmatch(value):
        raise PydanticCustomError(
            "invalid_date", "The date must be written as YYYY-MM-DD."
        )
    return value


Name50 = _text(50)
Label30 = _text(30)
CircleName = _text(60)
City = _text(60)
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


# ---- medical profile --------------------------------------------------


class ConditionsInput(Dto):
    status: Literal["none", "listed"]
    codes: list[Literal[CONDITION_CODES]] = Field(
        default_factory=list, max_length=len(CONDITION_CODES)
    )
    other: OtherText | None = None


class AllergiesInput(Dto):
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
    name: Name50
    relation: Literal[CONTACT_RELATIONS]
    phone_number: Phone


# ---- circles and patients ----------------------------------------------


class _Place(Dto):
    """City plus the optional point the app got from the phone's location."""

    city: City
    latitude: Latitude | None = None
    longitude: Longitude | None = None

    @model_validator(mode="after")
    def _both_or_neither(self):
        if (self.latitude is None) != (self.longitude is None):
            raise PydanticCustomError(
                "incomplete_location",
                "Send both latitude and longitude, or neither.",
            )
        return self


class _PatientBasics(_Place):
    birth_date: IsoDate
    medical_profile: MedicalProfileInput | None = None


class CreateSelfCircleInput(_PatientBasics):
    name: CircleName


class CreateOfflineCircleInput(_PatientBasics):
    name: CircleName
    patient_first_name: Name50
    patient_last_name: Name50


class CompleteRequestInput(_PatientBasics):
    pass


class PatientUpdateInput(_Place):
    birth_date: IsoDate
    first_name: Name50 | None = None
    last_name: Name50 | None = None


class RenameCircleInput(Dto):
    name: CircleName


class LeaveCircleInput(Dto):
    confirm_delete: Flag = False


# ---- requests and invitations --------------------------------------------


class CreationRequestInput(Dto):
    patient_phone_number: Phone
    circle_label: Label30
    proposed_app_mode: AppMode


class InviteInput(Dto):
    invitee_phone_number: Phone


class RespondInput(Dto):
    accept: Flag


# ---- account ------------------------------------------------------------


class DeleteAccountInput(Dto):
    patient_choice: Literal["delete", "continue"] | None = None
    delete_last_managed_circles: Flag = False
