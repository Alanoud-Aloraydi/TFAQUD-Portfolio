"""The rows of a change: the patient's conditions and allergies."""

from app.medical.checks import check_codes, check_other, invalid, ordered
from app.medical.parts import Allergies, Conditions
from app.models.medical import (
    CONDITION_CODES,
    FOOD_ALLERGY_CODES,
    MEDICATION_ALLERGY_CODES,
)


class ProfileRows:
    """Makes the condition and allergy rows."""

    @staticmethod
    def _condition_rows(value: Conditions) -> list[tuple]:
        """The rows to save for the conditions; «none» cannot come with any
        condition.
        """
        # «None» is the status alone, with no rows.
        if value.status == "none":
            if value.codes or value.other:
                raise invalid(
                    "conditions",
                    "none_is_exclusive",
                    "'No conditions' cannot be combined with other choices.",
                )
            return []
        # A list needs one item at least, known codes each once, and words when
        # «أخرى» is chosen; the rows in the app's order.
        if value.status != "listed":
            raise invalid("conditions", "unknown_choice", "Unknown status.")
        if not value.codes:
            raise invalid(
                "conditions", "empty_selection", "Choose at least one item."
            )
        check_codes("conditions", value.codes, CONDITION_CODES)
        other = check_other("conditions", value.codes, value.other)
        return [
            (code, other if code == "other" else None)
            for code in ordered(value.codes, CONDITION_CODES)
        ]

    @staticmethod
    def _allergy_rows(value: Allergies) -> list[tuple]:
        """The rows to save for the allergies; «none» cannot come with any
        allergy.
        """
        # «None» is one row, alone.
        if value.status == "none":
            if (
                value.medication
                or value.food
                or value.other_medication
                or (value.other_food)
            ):
                raise invalid(
                    "allergies",
                    "none_is_exclusive",
                    "'No allergies' cannot be combined with other choices.",
                )
            return []
        # A list needs one item at least, known codes each once, and words for
        # each «أخرى» chosen.
        if value.status != "listed":
            raise invalid("allergies", "unknown_choice", "Unknown status.")
        if not value.medication and not value.food:
            raise invalid(
                "allergies", "empty_selection", "Choose at least one item."
            )
        check_codes(
            "allergies.medication", value.medication, MEDICATION_ALLERGY_CODES
        )
        check_codes("allergies.food", value.food, FOOD_ALLERGY_CODES)
        other_medication = check_other(
            "allergies.other_medication",
            value.medication,
            value.other_medication,
        )
        other_food = check_other(
            "allergies.other_food", value.food, value.other_food
        )
        # The rows in the app's order: medication first, then food.
        rows = [
            ("medication", code, other_medication if code == "other" else None)
            for code in ordered(value.medication, MEDICATION_ALLERGY_CODES)
        ]
        rows += [
            ("food", code, other_food if code == "other" else None)
            for code in ordered(value.food, FOOD_ALLERGY_CODES)
        ]
        return rows
