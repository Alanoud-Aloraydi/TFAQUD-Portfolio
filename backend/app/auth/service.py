"""Session rules. No HTTP code here: only the rules.

Life of a session:

  create_session(user_id)   after the user proves their phone number (F01)
        -> access token (15 min) + refresh token (30 days)
  authenticate(access)      on every protected request
        -> checks signature, expiry, and that the session is not revoked
  refresh(refresh_token)    when the access token has expired
        -> a new access token for the same session
  sign_out(session_id)      when the user signs out
        -> the session is revoked; its tokens stop working immediately
"""

import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta

from app.auth.store import SessionRecord, SessionStore
from app.auth.tokens import (
    AccessClaims,
    decode_access_token,
    encode_access_token,
    hash_refresh_token,
    new_refresh_token,
)
from app.errors import Unauthorized


@dataclass(frozen=True)
class IssuedAccessToken:
    access_token: str
    access_token_expires_at: datetime


@dataclass(frozen=True)
class IssuedSession(IssuedAccessToken):
    refresh_token: str
    refresh_token_expires_at: datetime
    session_id: str


class SessionService:
    def __init__(
        self,
        store: SessionStore,
        secret_key: str,
        access_ttl: timedelta,
        refresh_ttl: timedelta,
        clock,
    ):
        self._store = store
        self._secret = secret_key
        self._access_ttl = access_ttl
        self._refresh_ttl = refresh_ttl
        self._clock = clock

    def create_session(self, user_id: str) -> IssuedSession:
        now = self._clock.now()
        session_id = uuid.uuid4().hex
        refresh_token = new_refresh_token()
        refresh_expires_at = now + self._refresh_ttl

        self._store.add(
            SessionRecord(
                id=session_id,
                user_id=user_id,
                refresh_token_hash=hash_refresh_token(refresh_token),
                created_at=now,
                refresh_expires_at=refresh_expires_at,
            )
        )
        access = self._issue_access_token(user_id, session_id, now)
        return IssuedSession(
            access_token=access.access_token,
            access_token_expires_at=access.access_token_expires_at,
            refresh_token=refresh_token,
            refresh_token_expires_at=refresh_expires_at,
            session_id=session_id,
        )

    def authenticate(self, access_token: str) -> AccessClaims:
        """Return who is calling, or raise Unauthorized."""
        claims = decode_access_token(
            self._secret, access_token, self._clock.now()
        )
        record = self._store.get(claims.session_id)
        # The signature alone is not enough: the session must still exist and
        # must not have been signed out.
        if (
            record is None
            or record.is_revoked
            or record.user_id != claims.user_id
            or self._clock.now() >= record.refresh_expires_at
        ):
            raise Unauthorized(
                "The session has ended. Sign in again.", code="session_revoked"
            )
        return claims

    def refresh(self, refresh_token: str) -> IssuedAccessToken:
        now = self._clock.now()
        record = self._store.get_by_refresh_hash(
            hash_refresh_token(refresh_token)
        )
        # One answer for every failure (unknown, revoked, expired): the app can
        # only do one thing in all three cases, which is to sign in again.
        if (
            record is None
            or record.is_revoked
            or now >= record.refresh_expires_at
        ):
            raise Unauthorized(
                "The refresh token is not valid. Sign in again.",
                code="invalid_refresh_token",
            )
        return self._issue_access_token(record.user_id, record.id, now)

    def sign_out(self, session_id: str) -> None:
        self._store.revoke(session_id, self._clock.now())

    def _issue_access_token(
        self, user_id: str, session_id: str, now: datetime
    ) -> IssuedAccessToken:
        expires_at = now + self._access_ttl
        token = encode_access_token(
            self._secret, user_id, session_id, now, expires_at
        )
        return IssuedAccessToken(
            access_token=token, access_token_expires_at=expires_at
        )
