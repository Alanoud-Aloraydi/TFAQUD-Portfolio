"""The field types of the medicine bodies: names, amounts, units, a skip
reason."""

import re
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import Field

Text50 = Annotated[str, Field(min_length=1, max_length=50)]
OptionalText250 = Annotated[str | None, Field(max_length=250)]
DoseValue = Annotated[
    Decimal,
    Field(gt=0, max_digits=10, decimal_places=3),
]
StrengthValue = Annotated[
    Decimal,
    Field(gt=0, max_digits=10, decimal_places=3),
]

DosageForm = Literal[
    "tablet", "capsule", "liquid", "drops", "inhaler", "nebulizer",
    "injection",
]
DoseUnit = Literal["tablet", "capsule", "mL", "drop", "puff", "unit"]
StrengthUnit = Literal[
    "mg", "mcg", "mg/mL", "mg/5mL", "mcg/dose", "unit/mL", "%"
]
SkipReason = Literal[
    "forgotten",
    "unavailable",
    "side_effects",
    "patient_refused",
    "other",
]

UNIT_BY_FORM = {
    "tablet": "tablet",
    "capsule": "capsule",
    "liquid": "mL",
    "drops": "drop",
    "inhaler": "puff",
    "nebulizer": "mL",
    "injection": {"mL", "unit"},
}

_ENGLISH_DECIMAL = re.compile(r"^(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$")


def english_decimal(value):
    """Reject localized digits and decimal text without a leading zero."""
    if isinstance(value, str) and not _ENGLISH_DECIMAL.fullmatch(value):
        raise ValueError("Use English digits with a leading zero.")
    return value


# «نذكرك كل … يوم»: from every day to every 90 days.
MAX_INTERVAL_DAYS = 90
