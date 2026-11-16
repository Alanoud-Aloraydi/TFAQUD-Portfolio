"""Session rules. No HTTP code here: only the rules.

Life of a session:

  create_session(user_id)   after the user proves their phone number (F01)
        -> access token (15 min) + refresh token (until sign-out)
  authenticate(access)      on every protected request
        -> checks signature, expiry, and that the session is not revoked
  refresh(refresh_token)    when the access token has expired
        -> a new access token for the same session
  sign_out(session_id)      when the user signs out
        -> the session is revoked; its tokens stop working immediately

A session has no end date. Only a revocation ends it: the user signing out,
the account deleted, or the server signing out a phone whose app Apple says
was deleted (`app.push.notify`)."""

import uuid
from datetime import timedelta

from app.auth.issued import IssuedSession
from app.auth.refresh_tokens import hash_refresh_token, new_refresh_token
from app.auth.session_tokens import SessionTokens
from app.auth.store import SessionRecord, SessionStore


class SessionService(SessionTokens):
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
