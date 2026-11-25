"""How the sign-in endpoints read a phone number and a code, and their
request bodies.

A value that does not fit is refused with `validation_error` (422) before
any rule runs, so a badly typed code is never sent to the SMS provider."""

import re
from typing import Annotated

from pydantic import AfterValidator, Field
from pydantic_core import PydanticCustomError

from app.sms.base import CODE_LENGTH
from app.validation import Dto


_PHONE_PATTERN = re.compile(r"^\+9665[0-9]{8}$")

_CODE_PATTERN = re.compile(rf"^[0-9]{{{CODE_LENGTH}}}$")

# U+0660..U+0669 (Arabic-Indic) and U+06F0..U+06F9 (Persian) -> 0..9.
# Written with numbers, not with the characters, so the source stays plain
# ASCII.
_DIGITS_TO_WESTERN = {
    **{0x0660 + i: ord("0") + i for i in range(10)},
    **{0x06F0 + i: ord("0") + i for i in range(10)},
}


def _check_phone(value: str) -> str:
    """Accept only a Saudi mobile number in the form +9665XXXXXXXX."""
    if not _PHONE_PATTERN.fullmatch(value):
        raise PydanticCustomError(
            "invalid_phone",
            "The phone number must be a Saudi mobile number in the form "
            "+9665XXXXXXXX.",
        )
    return value


def _check_code(value: str) -> str:
    """Accept a code of exactly six digits; Arabic-Indic or Persian digits
    are read as Western ones.
    """
    normalized = value.translate(_DIGITS_TO_WESTERN)
    if not _CODE_PATTERN.fullmatch(normalized):
        raise PydanticCustomError(
            "invalid_code_format",
            f"The code must be exactly {CODE_LENGTH} digits.",
        )
    return normalized


Phone = Annotated[str, Field(max_length=32), AfterValidator(_check_phone)]

Code = Annotated[str, Field(max_length=32), AfterValidator(_check_code)]

# An id that the server made (32 hex characters). The limit only protects the
# server from a huge value; whether the id exists is checked by the service.
VerificationId = Annotated[str, Field(min_length=1, max_length=64)]


class RefreshRequest(Dto):
    """The body of POST /auth/refresh."""

    refresh_token: str


class RequestCodeRequest(Dto):
    """The body of POST /auth/request-code."""

    phone_number: Phone
    # Send it back to ask for another SMS inside the same request (a resend).
    verification_id: VerificationId | None = None


class VerifyCodeRequest(Dto):
    """The body of POST /auth/verify-code."""

    verification_id: VerificationId
    code: Code
