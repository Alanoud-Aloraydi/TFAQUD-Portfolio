"""The request bodies of the sign-in endpoints."""

from app.auth.inputs import Code, Phone, VerificationId
from app.validation import Dto


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
