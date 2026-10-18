"""The two kinds of token.

Access token  - a signed JWT. Short life (15 minutes, proposal). The app sends it
                with every request. It carries the user id and the session id.
Refresh token - a random string. Long life (30 days, proposal). The app sends it
                only to get a new access token. It is not a JWT: it means
                nothing by itself and is valid only while the server has a
                matching, non-revoked session record.
"""

import hashlib
import secrets
from dataclasses import dataclass
from datetime import datetime

import jwt

from app.errors import Unauthorized

_ALGORITHM = "HS256"
_ACCESS_TYPE = "access"


@dataclass(frozen=True)
class AccessClaims:
    user_id: str
    session_id: str


def encode_access_token(
    secret: str, user_id: str, session_id: str, issued_at: datetime, expires_at: datetime
) -> str:
    payload = {
        "typ": _ACCESS_TYPE,
        "sub": user_id,
        "sid": session_id,
        "iat": int(issued_at.timestamp()),
        "exp": int(expires_at.timestamp()),
    }
    return jwt.encode(payload, secret, algorithm=_ALGORITHM)


def decode_access_token(secret: str, token: str, now: datetime) -> AccessClaims:
    """Check the signature and the expiry. Raises Unauthorized if either fails.

    All time checks are done here against our own clock, not the library's, so
    that tests can move time. The library's own time checks (exp, iat, nbf) are
    switched off for that reason.
    """
    try:
        payload = jwt.decode(
            token,
            secret,
            algorithms=[_ALGORITHM],  # never accept the algorithm the token names
            options={
                "verify_exp": False,
                "verify_iat": False,
                "verify_nbf": False,
                "require": ["typ", "sub", "sid", "exp"],
            },
        )
    except jwt.PyJWTError as exc:
        raise Unauthorized("The access token is not valid.", code="invalid_token") from exc

    if payload.get("typ") != _ACCESS_TYPE:
        raise Unauthorized("The access token is not valid.", code="invalid_token")
    if now.timestamp() >= payload["exp"]:
        raise Unauthorized("The access token has expired.", code="access_token_expired")

    return AccessClaims(user_id=payload["sub"], session_id=payload["sid"])


def new_refresh_token() -> str:
    return secrets.token_urlsafe(32)


def hash_refresh_token(refresh_token: str) -> str:
    return hashlib.sha256(refresh_token.encode("utf-8")).hexdigest()
