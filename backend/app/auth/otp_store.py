"""Where sign-in code requests are kept.

Our server, not the SMS provider, counts the wrong tries and limits the codes
(docs/api-contracts.md, section 8). This store holds what it needs to count.

Two kinds of record:

  OtpRequest  one "verification request". It starts when the app asks for a code
              and ends when a code is accepted. It counts the wrong tries (the
              limit is 3 per request) and remembers which phone number it is for.
              Asking again with the same `verification_id` (a resend) keeps the
              same request, so a new SMS does not give the user new tries.
  OtpSend     one SMS that was sent (or is being sent). The limit of 3 codes per
              phone number per hour is counted from these.

Two of the methods are "claims": `claim_send` and `claim_try`. They check the
limit and take the place in ONE step. Two requests that arrive at the same time
cannot both take the last place. With PostgreSQL this is one statement or one
transaction; here it is a lock.

`OtpStore` is the interface. `InMemoryOtpStore` is the only implementation for
now. It forgets everything on restart and is not shared between server
processes, so it is for development and tests only. A PostgreSQL store replaces
it once the tables from TFQD-7 exist. `tests/test_otp_store.py` is written
against the interface, so the same tests must pass for the new store.
"""

import threading
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, replace
from datetime import datetime


@dataclass(frozen=True)
class OtpRequest:
    id: str
    phone: str
    created_at: datetime
    wrong_tries: int = 0
    verified_at: datetime | None = None


@dataclass(frozen=True)
class OtpSend:
    id: str
    request_id: str
    phone: str
    sent_at: datetime


@dataclass(frozen=True)
class SendClaim:
    """The answer of `claim_send`.

    granted=True   the place is taken. `request_id` is the request the SMS belongs
                   to (new, or the one that was given) and `send_id` is the record
                   to give back with `release_send` if the SMS cannot be sent.
    granted=False  the phone number already has the maximum number of sends in
                   the window. `oldest_send_at` is the oldest send in the window:
                   the user can ask again when it leaves the window.
    """

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
    ) -> SendClaim:
        """Take one place in the phone number's hourly limit, if there is one.

        The sends of `phone` with `sent_at` AFTER `window_start` are counted. A
        send exactly on `window_start` is already outside the window. If fewer
        than `max_sends` are counted, a send is recorded with `sent_at=now`.

        `request_id=None` also creates a new request for `phone` in the same
        step, so a refused claim leaves nothing behind. A `request_id` that does
        not exist raises KeyError.
        """

    @abstractmethod
    def release_send(self, send_id: str) -> None:
        """Give back a place from `claim_send` because the SMS was not sent.

        If this was the only send of its request, the request is removed too.
        Releasing a send that does not exist does nothing.
        """

    @abstractmethod
    def latest_send_at(self, request_id: str) -> datetime | None:
        """When the last SMS of this request was sent, or None if there is none."""

    @abstractmethod
    def claim_try(self, request_id: str, max_tries: int) -> bool:
        """Count one try on the request, if fewer than `max_tries` are counted.

        Returns False (and counts nothing) when the request does not exist or has
        no tries left.
        """

    @abstractmethod
    def release_try(self, request_id: str) -> None:
        """Give back a try from `claim_try`. The count never goes below zero."""

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
    ) -> SendClaim:
        with self._lock:
            in_window = [
                s for s in self._sends.values() if s.phone == phone and s.sent_at > window_start
            ]
            if len(in_window) >= max_sends:
                return SendClaim(
                    granted=False, oldest_send_at=min(s.sent_at for s in in_window)
                )
            if request_id is None:
                request_id = uuid.uuid4().hex
                self._requests[request_id] = OtpRequest(
                    id=request_id, phone=phone, created_at=now
                )
            elif request_id not in self._requests:
                raise KeyError(request_id)
            send = OtpSend(
                id=uuid.uuid4().hex, request_id=request_id, phone=phone, sent_at=now
            )
            self._sends[send.id] = send
            return SendClaim(granted=True, request_id=request_id, send_id=send.id)

    def release_send(self, send_id: str) -> None:
        with self._lock:
            send = self._sends.pop(send_id, None)
            if send is None:
                return
            still_has_sends = any(s.request_id == send.request_id for s in self._sends.values())
            if not still_has_sends:
                self._requests.pop(send.request_id, None)

    def latest_send_at(self, request_id: str) -> datetime | None:
        with self._lock:
            times = [s.sent_at for s in self._sends.values() if s.request_id == request_id]
            return max(times) if times else None

    def claim_try(self, request_id: str, max_tries: int) -> bool:
        with self._lock:
            request = self._requests.get(request_id)
            if request is None or request.wrong_tries >= max_tries:
                return False
            self._requests[request_id] = replace(request, wrong_tries=request.wrong_tries + 1)
            return True

    def release_try(self, request_id: str) -> None:
        with self._lock:
            request = self._requests.get(request_id)
            if request is not None and request.wrong_tries > 0:
                self._requests[request_id] = replace(
                    request, wrong_tries=request.wrong_tries - 1
                )

    def mark_verified(self, request_id: str, at: datetime) -> bool:
        with self._lock:
            request = self._requests.get(request_id)
            if request is None or request.verified_at is not None:
                return False
            self._requests[request_id] = replace(request, verified_at=at)
            return True
