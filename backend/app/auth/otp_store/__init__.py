"""OTP metadata interface and a thread-safe implementation for unit tests.

Quota reservations include uncertain sends. Only confirmed failures release
quota. PostgreSQL provides durable storage through PostgresOtpStore."""

from app.auth.otp_store.interface import OtpStore
from app.auth.otp_store.judging import judge_send, next_send_at
from app.auth.otp_store.memory import InMemoryOtpStore
from app.auth.otp_store.records import AttemptsExhausted, OtpRequest, OtpSend
from app.auth.otp_store.rules import SendClaim, SendRules

__all__ = [
    "AttemptsExhausted",
    "InMemoryOtpStore",
    "OtpRequest",
    "OtpSend",
    "OtpStore",
    "SendClaim",
    "SendRules",
    "judge_send",
    "next_send_at",
]
