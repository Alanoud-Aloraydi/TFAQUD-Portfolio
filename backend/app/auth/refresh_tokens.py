"""Refresh tokens: a new random one, and the hash the server keeps."""

import hashlib
import secrets


def new_refresh_token() -> str:
    """A new random refresh token, long enough that it cannot be guessed."""
    return secrets.token_urlsafe(32)


def hash_refresh_token(refresh_token: str) -> str:
    """The SHA-256 of a refresh token: what the server keeps instead of the
    token.
    """
    return hashlib.sha256(refresh_token.encode("utf-8")).hexdigest()
