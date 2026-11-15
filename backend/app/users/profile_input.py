"""The body of PUT /accounts/me/profile and its name rules."""

import unicodedata
from typing import Annotated

from pydantic import AfterValidator, Field
from pydantic_core import PydanticCustomError

from app.circles.inputs import City, IsoDate
from app.validation import Dto


def _one_line(value: str) -> str:
    """Refuse a name with a line break or another control character."""
    # Control characters are invalid in displayed names.
    if any(unicodedata.category(ch) == "Cc" for ch in value):
        raise PydanticCustomError(
            "invalid_name",
            "A name cannot contain line breaks or control characters.",
        )
    return value


def _name(max_length: int):
    """A required one-line name of 1 to ``max_length`` characters.

    Length is counted in code points after trimming (Dto strips the
    surrounding whitespace first), as the ``account`` table's
    ``profile_names`` check counts it. The app limits its fields the same
    way (NameLimits, CodePointLengthFormatter).
    """
    return Annotated[
        str,
        Field(min_length=1, max_length=max_length),
        AfterValidator(_one_line),
    ]


class ProfileRequest(Dto):
    """The body of PUT /api/v1/accounts/me/profile."""

    first_name: _name(50)
    last_name: _name(50)
    display_name: _name(30)
    # Onboarding sends both; the account page sends neither, and then the
    # saved values stay.
    birth_date: IsoDate | None = None
    city: City | None = None
