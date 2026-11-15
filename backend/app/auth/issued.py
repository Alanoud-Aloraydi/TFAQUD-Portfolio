"""What a sign-in or a refresh gives the app."""

from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class IssuedAccessToken:
    """A new access token and when it ends."""

    access_token: str
    access_token_expires_at: datetime


@dataclass(frozen=True)
class IssuedSession(IssuedAccessToken):
    """What a sign-in gives the app: the access token and when it ends, the
    refresh token (which ends only at sign-out), and the session id.
    """

    refresh_token: str
    session_id: str
