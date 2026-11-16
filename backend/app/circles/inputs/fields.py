"""The field types the circle bodies share: names, a city, a zone,
dates, a point, flags."""

import re
import unicodedata
from datetime import date
from typing import Annotated, Literal

from pydantic import AfterValidator, BeforeValidator, Field
from pydantic_core import PydanticCustomError

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
