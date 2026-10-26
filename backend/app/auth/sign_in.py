"""Phone sign-in with atomic quota claims and durable session completion.

Authentica owns OTP generation and verification. The application limits
attempts and sends, preserving quota when delivery cannot be confirmed.
"""

import math
from contextlib import nullcontext
from dataclasses import dataclass
from datetime import timedelta

from app.auth.otp_store import OtpStore
from app.auth.service import IssuedSession, SessionService
from app.errors import (
    NotFound,
    ServiceUnavailable,
    TooManyRequests,
    ValidationFailed,
)
from app.sms.base import SmsDeliveryError, SmsSender
from app.users.store import User, UserStore

# "per hour" in the user stories. A fixed rule, not a setting.
SEND_WINDOW = timedelta(hours=1)


@dataclass(frozen=True)
class SignInResult:
    session: IssuedSession
    user: User
    created: bool  # True if this sign-in created the user


class SignInService:
    def __init__(
        self,
        otp_store: OtpStore,
        user_store: UserStore,
        sms_sender: SmsSender,
        session_service: SessionService,
        clock,
        *,
        otp_valid_seconds: int,
        max_wrong_tries: int,
        max_sends_per_hour: int,
        transaction=nullcontext,
    ):
        self._otp = otp_store
        self._users = user_store
        self._sms = sms_sender
        self._sessions = session_service
        self._clock = clock
        self._valid_for = timedelta(seconds=otp_valid_seconds)
        self._max_wrong_tries = max_wrong_tries
        self._max_sends = max_sends_per_hour
        self._transaction = transaction

    def request_code(
        self, phone: str, verification_id: str | None = None
    ) -> str:
        """Send a code to `phone`. Returns the verification id.

        Without `verification_id` a new request starts, with its own 3 tries.
        With it, the SMS is a resend inside the same request: the tries already
        used stay used.
        """
        if verification_id is not None:
            request = self._otp.get_request(verification_id)
            # An id that is unknown, belongs to another phone number, or is
            # finished all get the same answer. The app starts a new request.
            if (
                request is None
                or request.phone != phone
                or request.status != "pending"
            ):
                raise NotFound(
                    "No open verification request exists. Start again.",
                    code="verification_not_found",
                )
            if request.wrong_tries >= self._max_wrong_tries:
                raise TooManyRequests(
                    "This request has no tries left. Start a new one.",
                    code="too_many_attempts",
                )

        now = self._clock.now()
        try:
            claim = self._otp.claim_send(
                verification_id, phone, now, now - SEND_WINDOW, self._max_sends
            )
        except KeyError:
            raise NotFound(code="verification_not_found") from None
        if not claim.granted:
            wait = (claim.oldest_send_at + SEND_WINDOW) - now
            raise TooManyRequests(
                "Too many codes were sent. Try again later.",
                code="too_many_codes",
                retry_after=max(1, math.ceil(wait.total_seconds())),
            )

        self._send_code(phone, claim.send_id)
        return claim.request_id

    def _send_code(self, phone: str, send_id: str) -> None:
        """Release quota only when the provider confirms rejection."""
        try:
            self._sms.send_code(phone)
        except SmsDeliveryError as error:
            if error.delivery_rejected:
                self._otp.release_send(send_id)
            raise ServiceUnavailable(
                "The code could not be sent. Try again.",
                code="sms_unavailable",
            ) from None
        sent_at = self._clock.now()
        self._otp.mark_sent(send_id, sent_at, sent_at + self._valid_for)

    def _verification_request(self, verification_id):
        """Reject closed or expired challenges before calling the provider."""
        request = self._otp.get_request(verification_id)
        if request is None:
            raise NotFound(
                "There is no verification request with this id. Start again.",
                code="verification_not_found",
            )
        if request.verified_at is not None:
            raise ValidationFailed(
                "This request is already finished. Start again.",
                code="code_already_used",
            )
        if request.status != "pending":
            raise NotFound(code="verification_not_found")
        if (
            request.expires_at is None
            or self._clock.now() > request.expires_at
        ):
            raise ValidationFailed(
                "The code has expired. Ask for a new one.", code="code_expired"
            )
        return request

    def verify_code(self, verification_id: str, code: str) -> SignInResult:
        """Verify a pending challenge and start an account session."""
        request = self._verification_request(verification_id)
        if not self._otp.claim_try(verification_id, self._max_wrong_tries):
            self._verification_request(verification_id)
            raise TooManyRequests(
                "This request has no tries left. Start a new one.",
                code="too_many_attempts",
            )
        try:
            accepted = self._sms.check_code(request.phone, code)
        except SmsDeliveryError:
            self._otp.release_try(verification_id)
            raise ServiceUnavailable(
                "The code could not be checked. Try again.",
                code="sms_unavailable",
            ) from None

        if not accepted:
            last_sent = self._otp.latest_send_at(verification_id)
            if (
                last_sent is None
                or self._clock.now() - last_sent > self._valid_for
            ):
                self._otp.release_try(verification_id)
                raise ValidationFailed(
                    "The code has expired. Ask for a new one.",
                    code="code_expired",
                )
            raise ValidationFailed(
                "The code is not correct.", code="invalid_code"
            )

        return self._complete_sign_in(request)

    def _complete_sign_in(self, request) -> SignInResult:
        """Consume the challenge and persist account/session atomically."""
        with self._transaction():
            if not self._otp.mark_verified(request.id, self._clock.now()):
                raise ValidationFailed(
                    "This request is already finished. Start again.",
                    code="code_already_used",
                )
            user, created = self._users.get_or_create_by_phone(
                request.phone, self._clock.now()
            )
            session = self._sessions.create_session(user.id)
            return SignInResult(session=session, user=user, created=created)
