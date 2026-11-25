"""Session rules, without HTTP.

Life of a session:
    create_session(user_id)   after the user proves their phone number
                              -> access token (15 min) + refresh token
    authenticate(access)      on every protected request
    refresh(refresh_token)    when the access token has expired
    sign_out(session_id)      the session ends; its tokens stop working"""

import uuid
from datetime import datetime, timedelta

from app.auth.sessions import SessionRecord, SessionStore
from app.auth.tokens import (
    AccessClaims,
    IssuedAccessToken,
    IssuedSession,
    decode_access_token,
    encode_access_token,
    hash_refresh_token,
    new_refresh_token,
)
from app.errors import Unauthorized


class SessionService:
    """Starts, refreshes and ends sign-in sessions: a short access token for
    each request, and a refresh token, kept until sign-out, to get a new one.
    """

    def __init__(
        self,
        store: SessionStore,
        secret_key: str,
        access_ttl: timedelta,
        clock,
    ):
        """Keep the store, the signing key, the access lifetime and the
        clock.
        """
        self._store = store
        self._secret = secret_key
        self._access_ttl = access_ttl
        self._clock = clock

    def create_session(self, user_id: str) -> IssuedSession:
        """Start a session for `user_id`: keep its record (with only the
        refresh token's hash) and give both tokens.
        """
        # Keep the session with only the refresh token's hash; the token itself
        # goes to the app once.
        now = self._clock.now()
        session_id = uuid.uuid4().hex
        refresh_token = new_refresh_token()

        self._store.add(
            SessionRecord(
                id=session_id,
                user_id=user_id,
                refresh_token_hash=hash_refresh_token(refresh_token),
                created_at=now,
            )
        )
        # And a first access token.
        access = self._issue_access_token(user_id, session_id, now)
        return IssuedSession(
            access_token=access.access_token,
            access_token_expires_at=access.access_token_expires_at,
            refresh_token=refresh_token,
            session_id=session_id,
        )

    def sign_out(self, session_id: str) -> None:
        """End the session; its tokens stop working."""
        self._store.revoke(session_id, self._clock.now())

    # Checks access tokens and issues new ones.
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
