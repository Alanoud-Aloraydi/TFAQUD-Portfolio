"""What every store of sign-in codes does."""

from abc import ABC, abstractmethod
from datetime import datetime

from app.auth.otp_store.records import OtpRequest
from app.auth.otp_store.rules import SendClaim, SendRules


class OtpStore(ABC):
    """Where sign-in requests and their sends are kept; every change is one
    atomic step, so two requests at once cannot both take the last place.
    """

    # The request with this id, or None.
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
        rules: SendRules | None = None,
    ) -> SendClaim:
        """Take one place in the phone number's limit, if there is one.

        With `rules`, the number's sends count only after its last accepted
        code (a successful sign-in starts it again), the waits between codes
        apply, and so do the caps of the asking device and IP
        (`judge_send`). A known phone (see `SendRules`) counts only its own
        sends to the number and has no IP cap.

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
