"""Atomic PostgreSQL quota claims for provider-managed OTP verification."""

from app.auth.postgres_otp.store import PostgresOtpStore

__all__ = [
    "PostgresOtpStore",
]
