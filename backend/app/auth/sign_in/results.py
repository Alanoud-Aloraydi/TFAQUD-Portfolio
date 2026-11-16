"""What a sign-in answers: a code sent, or a finished sign-in."""

from dataclasses import dataclass

from app.auth.issued import IssuedSession
from app.users.user import User


@dataclass(frozen=True)
class CodeSent:
    """A code was sent: the request's id, and the seconds until the number may
    get another.
    """

    request_id: str
    resend_after_seconds: int  # until the number may get one more code


@dataclass(frozen=True)
class SignInResult:
    """A finished sign-in: the new session, the account, and whether the
    account is new.
    """

    session: IssuedSession
    user: User
    created: bool  # True if this sign-in created the user
