"""Request bodies of the circle endpoints (see app/validation.py): the
field types they share, the medical file, and deleting one's account."""

import re
import unicodedata
from datetime import date
from typing import Annotated, Literal

from pydantic import AfterValidator, BeforeValidator, Field
from pydantic_core import PydanticCustomError

from app.auth.inputs import Phone
from app.medical import Allergies, Conditions, MedicalUpdate, UNSET
from app.models.circle import BLOOD_TYPES
from app.models.medical import (
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
    """One emergency contact: name, relation (with its words for «أخرى»)
    and a Saudi mobile number."""

    name: Name50
    relation: Literal[CONTACT_RELATIONS]
    relation_other: OtherText | None = None
    phone_number: Phone


class DeleteAccountInput(Dto):
    """The body of deleting one's account: a patient chooses whether their
    circle is deleted or its care continues, and the last manager of a circle
    confirms its deletion.
    """

    patient_choice: Literal["delete", "continue"] | None = None
    delete_last_managed_circles: Flag = False
