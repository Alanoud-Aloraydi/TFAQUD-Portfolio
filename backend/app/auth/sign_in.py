"""Phone sign-in with atomic quota claims and durable session completion.

Authentica owns OTP generation and verification. The application limits
attempts and sends, preserving quota when delivery cannot be confirmed.
"""

import math
from contextlib import nullcontext
from dataclasses import dataclass
from datetime import timedelta

from app import metrics
from app.auth.otp_store import AttemptsExhausted, OtpStore, SendRules
from app.auth.service import IssuedSession, SessionService
from app.errors import (
    NotFound,
    ServiceUnavailable,
    TooManyRequests,
    ValidationFailed,
)
from app.sms.base import SmsDeliveryError, SmsSender
from app.users.store import User, UserStore

# The codes to one phone number count for 24 hours (and only since its last
# accepted code); the codes of one device or one IP for one hour.
SEND_WINDOW = timedelta(hours=24)
ASKER_WINDOW = timedelta(hours=1)


@dataclass(frozen=True)
class CodeSent:
    """A code was sent: the request's id, and the seconds until the number may
    get another.
    """

    request_id: str
    resend_after_seconds: int  # until the number may get one more code


@dataclass(frozen=True)
class SignInResult:
    """A finished sign-in: the new session, the account, and whether the
    account is new.
    """

    session: IssuedSession
    user: User
    created: bool  # True if this sign-in created the user


class SignInService:
    """Phone sign-in: sends codes within the limits, checks them, and starts a
    session for a right one.
    """

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
        max_sends_per_day: int,
        resend_waits: tuple[int, ...] = (),
        max_sends_per_device_hour: int | None = None,
        max_sends_per_ip_hour: int | None = None,
        transaction=nullcontext,
    ):
        """Keep the stores, the sender, the session service, the clock and the
        limits.
        """
        self._otp = otp_store
        self._users = user_store
        self._sms = sms_sender
        self._sessions = session_service
        self._clock = clock
        self._valid_for = timedelta(seconds=otp_valid_seconds)
        self._max_wrong_tries = max_wrong_tries
        self._max_sends = max_sends_per_day
        self._waits = tuple(resend_waits)
        self._max_device_sends = max_sends_per_device_hour
        self._max_ip_sends = max_sends_per_ip_hour
        self._transaction = transaction

    def send_code(
        self,
        phone: str,
        verification_id: str | None = None,
        *,
        device_id: str | None = None,
        client_ip: str | None = None,
    ) -> CodeSent:
        """Send a code to `phone`, and say when the number may get one more.

        Without `verification_id` a new request starts, with its own 3 tries.
        With it, the SMS is a resend inside the same request: the tries already
        used stay used.

        Refused with "resend_wait" when it is too soon after the last code to
        this number (the wait grows with each code, up to 10 minutes), and
        with "too_many_codes" when the number had its codes for the day, or
        the asking device or IP had theirs for the hour.
        """
        # Take a place in every limit at once (the store decides atomically),
        # or learn why not and until when.
        now = self._clock.now()
        rules = SendRules(
            waits=self._waits,
            device_id=device_id,
            client_ip=client_ip,
            requester_window=ASKER_WINDOW,
            max_device_sends=self._max_device_sends,
            max_ip_sends=self._max_ip_sends,
        )
        try:
            claim = self._otp.claim_send(
                verification_id,
                phone,
                now,
                now - SEND_WINDOW,
                self._max_sends,
                max_tries=self._max_wrong_tries,
                rules=rules,
            )
        except AttemptsExhausted:
            raise TooManyRequests(
                "This request has no tries left. Start a new one.",
                code="too_many_attempts",
            ) from None
        except KeyError:
            raise NotFound(code="verification_not_found") from None
        # Refused: say which limit, and in how many seconds to come back.
        if not claim.granted:
            wait = claim.retry_at - now
            retry_after = max(1, math.ceil(wait.total_seconds()))
            if claim.reason == "wait":
                raise TooManyRequests(
                    "A code was sent a moment ago. Wait before the next one.",
                    code="resend_wait",
                    retry_after=retry_after,
                )
            raise TooManyRequests(
                "Too many codes were sent. Try again later.",
                code="too_many_codes",
                retry_after=retry_after,
            )

        self._send_code(phone, claim.send_id)
        ready = claim.next_send_at or now
        return CodeSent(
            request_id=claim.request_id,
            resend_after_seconds=max(
                0, math.ceil((ready - now).total_seconds())
            ),
        )

    def _send_code(self, phone: str, send_id: str) -> None:
        """Release quota only when the provider confirms rejection."""
        try:
            self._sms.send_code(phone)
        except SmsDeliveryError as error:
            metrics.increment("sign_in.code_not_sent")
            if error.delivery_rejected:
                self._otp.release_send(send_id)
            raise ServiceUnavailable(
                "The code could not be sent. Try again.",
                code="sms_unavailable",
            ) from None
        metrics.increment("sign_in.code_sent")
        sent_at = self._clock.now()
        self._otp.mark_sent(send_id, sent_at, sent_at + self._valid_for)

    def _verification_request(self, verification_id):
        """Reject closed or expired challenges before calling the provider."""
        # Unknown or replaced: 404; accepted already: «already used»; past its
        # time: «expired».
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
        # An open, unexpired request; count the try before asking the provider.
        request = self._verification_request(verification_id)
        if not self._otp.claim_try(verification_id, self._max_wrong_tries):
            self._verification_request(verification_id)
            raise TooManyRequests(
                "This request has no tries left. Start a new one.",
                code="too_many_attempts",
            )
        # The provider could not decide: the try is given back.
        try:
            accepted = self._sms.check_code(request.phone, code)
        except SmsDeliveryError:
            metrics.increment("sign_in.code_not_checked")
            self._otp.release_try(verification_id)
            raise ServiceUnavailable(
                "The code could not be checked. Try again.",
                code="sms_unavailable",
            ) from None

        # Refused: a code past its time is «expired» (the try is given back),
        # any other is «not correct».
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
            metrics.increment("sign_in.invalid_code")
            raise ValidationFailed(
                "The code is not correct.", code="invalid_code"
            )

        # Right: close the request, and start the session.
        result = self._complete_sign_in(request)
        metrics.increment("sign_in.completed")
        return result

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
