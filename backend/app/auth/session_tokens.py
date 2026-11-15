"""Checking an access token, and a new one for a live refresh token."""

from datetime import datetime

from app.auth.issued import IssuedAccessToken
from app.auth.refresh_tokens import hash_refresh_token
from app.auth.tokens import (
    AccessClaims,
    decode_access_token,
    encode_access_token,
)
from app.errors import Unauthorized


class SessionTokens:
    """Checks access tokens and issues new ones."""

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
        ):
            raise Unauthorized(
                "The session has ended. Sign in again.", code="session_revoked"
            )
        return claims

    def refresh(self, refresh_token: str) -> IssuedAccessToken:
        """A new access token for a live session's refresh token; the same
        refusal for an unknown or signed-out one.
        """
        now = self._clock.now()
        record = self._store.get_by_refresh_hash(
            hash_refresh_token(refresh_token)
        )
        # One answer for both failures (unknown, signed out): the app can only
        # do one thing in both cases, which is to sign in again.
        if record is None or record.is_revoked:
            raise Unauthorized(
                "The refresh token is not valid. Sign in again.",
                code="invalid_refresh_token",
            )
        return self._issue_access_token(record.user_id, record.id, now)

    def _issue_access_token(
        self, user_id: str, session_id: str, now: datetime
    ) -> IssuedAccessToken:
        """Sign an access token for the user and session, ending after the
        access lifetime.
        """
        expires_at = now + self._access_ttl
        token = encode_access_token(
            self._secret, user_id, session_id, now, expires_at
        )
        return IssuedAccessToken(
            access_token=token, access_token_expires_at=expires_at
        )
