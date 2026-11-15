"""Phone sign-in with atomic quota claims and durable session completion.

Authentica owns OTP generation and verification. The application limits
attempts and sends, preserving quota when delivery cannot be confirmed."""

from app.auth.sign_in.results import CodeSent, SignInResult
from app.auth.sign_in.service import SignInService

__all__ = [
    "CodeSent",
    "SignInResult",
    "SignInService",
]
