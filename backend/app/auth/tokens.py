"""The tokens of a sign-in, and what a sign-in or a refresh gives the app.

Access token - a signed JWT with a short life (15 minutes). The app sends
it with every request. It carries the user id and the session id.

Refresh token - a random string with no end date: it works until its
session is signed out. The server keeps only its hash."""

import hashlib
import secrets
from dataclasses import dataclass
from datetime import datetime

import jwt

from app.errors import Unauthorized


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


def new_refresh_token() -> str:
    """A new random refresh token, long enough that it cannot be guessed."""
    return secrets.token_urlsafe(32)


def hash_refresh_token(refresh_token: str) -> str:
    """The SHA-256 of a refresh token: what the server keeps instead of the
    token.
    """
    return hashlib.sha256(refresh_token.encode("utf-8")).hexdigest()


_ALGORITHM = "HS256"

_ACCESS_TYPE = "access"


@dataclass(frozen=True)
class AccessClaims:
    """What a valid access token says: the account and the session."""

    user_id: str
    session_id: str


def encode_access_token(
    secret: str,
    user_id: str,
    session_id: str,
    issued_at: datetime,
    expires_at: datetime,
) -> str:
    """Sign a short access token (a JWT) for the account and session, valid
    until `expires_at`.
    """
    payload = {
        "typ": _ACCESS_TYPE,
        "sub": user_id,
        "sid": session_id,
        "iat": int(issued_at.timestamp()),
        "exp": int(expires_at.timestamp()),
    }
    return jwt.encode(payload, secret, algorithm=_ALGORITHM)


def decode_access_token(
    secret: str, token: str, now: datetime
) -> AccessClaims:
    """Check the signature and the expiry. Raises Unauthorized if either fails.

    All time checks are done here against our own clock, not the library's, so
    that tests can move time. The library's own time checks (exp, iat, nbf) are
    switched off for that reason.
    """
    try:
        payload = jwt.decode(
            token,
            secret,
            # Never accept the algorithm the token names.
            algorithms=[_ALGORITHM],
            options={
                "verify_exp": False,
                "verify_iat": False,
                "verify_nbf": False,
                "require": ["typ", "sub", "sid", "exp"],
            },
        )
    except jwt.PyJWTError as exc:
        raise Unauthorized(
            "The access token is not valid.", code="invalid_token"
        ) from exc

    if payload.get("typ") != _ACCESS_TYPE:
        raise Unauthorized(
            "The access token is not valid.", code="invalid_token"
        )
    if now.timestamp() >= payload["exp"]:
        raise Unauthorized(
            "The access token has expired.", code="access_token_expired"
        )

    return AccessClaims(user_id=payload["sub"], session_id=payload["sid"])
