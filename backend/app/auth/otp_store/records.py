"""The records of sign-in codes: a request, one send, and the error for a
request with no tries left."""

from dataclasses import dataclass
from datetime import datetime


class AttemptsExhausted(Exception):
    """A challenge has no remaining verification attempts."""


@dataclass(frozen=True)
class OtpRequest:
    """One sign-in attempt for a phone number: its wrong tries, whether its
    code was accepted, and until when its code is valid.
    """

    id: str
    phone: str
    created_at: datetime
    wrong_tries: int = 0
    verified_at: datetime | None = None
    status: str = "pending"
    expires_at: datetime | None = None


@dataclass(frozen=True)
class OtpSend:
    """One code sent (or reserved to send) for a request; reserved, sent or
    failed, with the device and IP that asked.
    """

    id: str
    request_id: str
    phone: str
    created_at: datetime
    sent_at: datetime | None = None
    status: str = "reserved"
    device_id: str | None = None
    client_ip: str | None = None
