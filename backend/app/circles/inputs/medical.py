"""The bodies of the medical file: conditions, allergies, the profile and
an emergency contact."""

from typing import Literal

from pydantic import Field

from app.auth.inputs import Phone
from app.circles.inputs.fields import Name50, OtherText
from app.medical import UNSET, Allergies, Conditions, MedicalUpdate
from app.models.medical import (
    BLOOD_TYPES,
    CONDITION_CODES,
    CONTACT_RELATIONS,
    FOOD_ALLERGY_CODES,
    MEDICATION_ALLERGY_CODES,
)
from app.validation import Dto


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
