"""OTP metadata interface and a thread-safe implementation for unit tests.

Quota reservations include uncertain sends. Only confirmed failures release
quota. PostgreSQL provides durable storage through PostgresOtpStore.
"""

import threading
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, replace
from datetime import datetime


class AttemptsExhausted(Exception):
    """A challenge has no remaining verification attempts."""


@dataclass(frozen=True)
class OtpRequest:
    id: str
    phone: str
    created_at: datetime
    wrong_tries: int = 0
    verified_at: datetime | None = None
    status: str = "pending"
    expires_at: datetime | None = None


@dataclass(frozen=True)
class OtpSend:
    id: str
    request_id: str
    phone: str
    created_at: datetime
    sent_at: datetime | None = None
    status: str = "reserved"


@dataclass(frozen=True)
class SendClaim:
    """A quota reservation, or the oldest timestamp blocking another send."""

    granted: bool
    request_id: str | None = None
    send_id: str | None = None
    oldest_send_at: datetime | None = None


class OtpStore(ABC):
    @abstractmethod
    def get_request(self, request_id: str) -> OtpRequest | None: ...

    @abstractmethod
    def claim_send(
        self,
        request_id: str | None,
        phone: str,
        now: datetime,
        window_start: datetime,
        max_sends: int,
        *,
        max_tries: int | None = None,
    ) -> SendClaim:
        """Take one place in the phone number's hourly limit, if there is one.

        Nonfailed reservations created after `window_start` count toward quota.
        A reservation exactly on `window_start` is outside the window.

        `request_id=None` also creates a new request for `phone` in the same
        step; a refused claim creates nothing. Unknown or closed IDs raise
        KeyError. Exhausted resend requests raise AttemptsExhausted.
        """

    @abstractmethod
    def release_send(self, send_id: str) -> None:
        """Release quota after a confirmed delivery failure; retain history."""

    @abstractmethod
    def mark_sent(
        self, send_id: str, at: datetime, expires_at: datetime
    ) -> None:
        """Confirm delivery and update the challenge's OTP expiration."""

    @abstractmethod
    def latest_send_at(self, request_id: str) -> datetime | None:
        """Return the latest confirmed send time, or None."""

    @abstractmethod
    def claim_try(self, request_id: str, max_tries: int) -> bool:
        """Count one try on the request, if fewer than `max_tries` are counted.

        Return False without counting when the request is closed or exhausted.
        """

    @abstractmethod
    def release_try(self, request_id: str) -> None:
        """Release an undecided try without making the count negative."""

    @abstractmethod
    def mark_verified(self, request_id: str, at: datetime) -> bool:
        """Close the request because its code was accepted.

        Returns True if this call closed it, False if it was already closed or
        does not exist.
        """


class InMemoryOtpStore(OtpStore):
    def __init__(self):
        self._lock = threading.Lock()
        self._requests: dict[str, OtpRequest] = {}
        self._sends: dict[str, OtpSend] = {}

    def get_request(self, request_id: str) -> OtpRequest | None:
        with self._lock:
            return self._requests.get(request_id)

    def claim_send(
        self,
        request_id: str | None,
        phone: str,
        now: datetime,
        window_start: datetime,
        max_sends: int,
        *,
        max_tries: int | None = None,
    ) -> SendClaim:
        with self._lock:
            if request_id is not None:
                request = self._requests.get(request_id)
                if (
                    request is None
                    or request.phone != phone
                    or request.status != "pending"
                ):
                    raise KeyError(request_id)
                if max_tries is not None and request.wrong_tries >= max_tries:
                    raise AttemptsExhausted()
            in_window = [
                s
                for s in self._sends.values()
                if s.phone == phone
                and s.created_at > window_start
                and s.status != "failed"
            ]
            if len(in_window) >= max_sends:
                return SendClaim(
                    granted=False,
                    oldest_send_at=min(s.created_at for s in in_window),
                )
            if request_id is None:
                for key, request in self._requests.items():
                    if request.phone == phone and request.status == "pending":
                        self._requests[key] = replace(
                            request, status="superseded"
                        )
                request_id = uuid.uuid4().hex
                self._requests[request_id] = OtpRequest(
                    id=request_id, phone=phone, created_at=now
                )
            send = OtpSend(
                id=uuid.uuid4().hex,
                request_id=request_id,
                phone=phone,
                created_at=now,
            )
            self._sends[send.id] = send
            return SendClaim(
                granted=True, request_id=request_id, send_id=send.id
            )

    def release_send(self, send_id: str) -> None:
        with self._lock:
            send = self._sends.get(send_id)
            if send is not None and send.status == "reserved":
                self._sends[send_id] = replace(send, status="failed")

    def mark_sent(self, send_id, at, expires_at):
        with self._lock:
            send = self._sends.get(send_id)
            if send is None or send.status != "reserved":
                return
            self._sends[send_id] = replace(send, status="sent", sent_at=at)
            request = self._requests[send.request_id]
            if request.status == "pending":
                expiration = max(request.expires_at or expires_at, expires_at)
                self._requests[request.id] = replace(
                    request, expires_at=expiration
                )

    def latest_send_at(self, request_id: str) -> datetime | None:
        with self._lock:
            times = [
                s.sent_at
                for s in self._sends.values()
                if s.request_id == request_id and s.status == "sent"
            ]
            return max(times) if times else None

    def claim_try(self, request_id: str, max_tries: int) -> bool:
        with self._lock:
            request = self._requests.get(request_id)
            if (
                request is None
                or request.status != "pending"
                or request.wrong_tries >= max_tries
            ):
                return False
            self._requests[request_id] = replace(
                request, wrong_tries=request.wrong_tries + 1
            )
            return True

    def release_try(self, request_id: str) -> None:
        with self._lock:
            request = self._requests.get(request_id)
            if (
                request is not None
                and request.status == "pending"
                and request.wrong_tries > 0
            ):
                self._requests[request_id] = replace(
                    request, wrong_tries=request.wrong_tries - 1
                )

    def mark_verified(self, request_id: str, at: datetime) -> bool:
        with self._lock:
            request = self._requests.get(request_id)
            if request is None or request.status != "pending":
                return False
            self._requests[request_id] = replace(
                request, status="verified", verified_at=at
            )
            return True
