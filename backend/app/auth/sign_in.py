"""Sign-in with the phone number and the code (feature F01). No HTTP code here.

The steps, as the app sees them:

  1. request_code(phone)                   an SMS with a code is sent; the app gets
                                           a `verification_id`.
     request_code(phone, verification_id)  a resend: another SMS, the same request.
  2. verify_code(verification_id, code)    if the code is right, the user is found
                                           (or created) and a session is started.

Who does what:
  - The SMS provider (Authentica) makes the code, sends it, and says whether a
    code is right. It blocks nothing (docs/api-contracts.md, section 8).
  - This class applies the rules of TFQD-13 / TFQD-35:
      * at most 3 wrong tries per verification request;
      * at most 3 codes sent per phone number per hour;
      * the limits do not reset when a new SMS is sent for the same request.
    There is no limit by device or IP address, and no lock on the phone number.

Two ideas keep the counting honest:
  - A limit is taken BEFORE the provider is called (claim), and given back if the
    provider could not answer (release). Only a provider answer "wrong code"
    keeps a try counted. So an outage on the provider's side never costs the user
    a try or a code.
  - A wrong code that arrives after the code has expired is not counted. The
    user could not have typed a right code, so it is not a mistake.
"""

import math
from dataclasses import dataclass
from datetime import timedelta

from app.auth.otp_store import OtpStore
from app.auth.service import IssuedSession, SessionService
from app.errors import NotFound, ServiceUnavailable, TooManyRequests, ValidationFailed
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
    ):
        self._otp = otp_store
        self._users = user_store
        self._sms = sms_sender
        self._sessions = session_service
        self._clock = clock
        self._valid_for = timedelta(seconds=otp_valid_seconds)
        self._max_wrong_tries = max_wrong_tries
        self._max_sends = max_sends_per_hour

    def request_code(self, phone: str, verification_id: str | None = None) -> str:
        """Send a code to `phone`. Returns the verification id.

        Without `verification_id` a new request starts, with its own 3 tries.
        With it, the SMS is a resend inside the same request: the tries already
        used stay used.
        """
        if verification_id is not None:
            request = self._otp.get_request(verification_id)
            # An id that is unknown, belongs to another phone number, or is
            # finished all get the same answer. The app starts a new request.
            if request is None or request.phone != phone or request.verified_at is not None:
                raise NotFound(
                    "There is no open verification request with this id. Start again.",
                    code="verification_not_found",
                )
            if request.wrong_tries >= self._max_wrong_tries:
                # Another SMS would be pointless: this request accepts no more tries.
                raise TooManyRequests(
                    "This request has no tries left. Start a new one.",
                    code="too_many_attempts",
                )

        now = self._clock.now()
        claim = self._otp.claim_send(
            verification_id, phone, now, now - SEND_WINDOW, self._max_sends
        )
        if not claim.granted:
            wait = (claim.oldest_send_at + SEND_WINDOW) - now
            raise TooManyRequests(
                "Too many codes were sent to this phone number. Try again later.",
                code="too_many_codes",
                retry_after=max(1, math.ceil(wait.total_seconds())),
            )

        try:
            self._sms.send_code(phone)
        except SmsDeliveryError:
            # The SMS was not sent, so it must not count against the hourly limit.
            self._otp.release_send(claim.send_id)
            raise ServiceUnavailable(
                "The code could not be sent. Try again.", code="sms_unavailable"
            ) from None
        return claim.request_id

    def verify_code(self, verification_id: str, code: str) -> SignInResult:
        """Check `code`. If it is right, start a session for the phone's user."""
        request = self._otp.get_request(verification_id)
        if request is None:
            raise NotFound(
                "There is no verification request with this id. Start again.",
                code="verification_not_found",
            )
        if request.verified_at is not None:
            raise ValidationFailed(
                "This request is already finished. Start again.", code="code_already_used"
            )

        # Take the try first, then ask the provider (see the module comment).
        if not self._otp.claim_try(verification_id, self._max_wrong_tries):
            raise TooManyRequests(
                "This request has no tries left. Start a new one.",
                code="too_many_attempts",
            )
        try:
            accepted = self._sms.check_code(request.phone, code)
        except SmsDeliveryError:
            self._otp.release_try(verification_id)
            raise ServiceUnavailable(
                "The code could not be checked. Try again.", code="sms_unavailable"
            ) from None

        if not accepted:
            last_sent = self._otp.latest_send_at(verification_id)
            if last_sent is None or self._clock.now() - last_sent > self._valid_for:
                self._otp.release_try(verification_id)
                raise ValidationFailed(
                    "The code has expired. Ask for a new one.", code="code_expired"
                )
            raise ValidationFailed("The code is not correct.", code="invalid_code")

        if not self._otp.mark_verified(verification_id, self._clock.now()):
            raise ValidationFailed(
                "This request is already finished. Start again.", code="code_already_used"
            )
        user, created = self._users.get_or_create_by_phone(request.phone, self._clock.now())
        session = self._sessions.create_session(user.id)
        return SignInResult(session=session, user=user, created=created)
