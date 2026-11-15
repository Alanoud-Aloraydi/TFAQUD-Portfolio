"""The phone sign-in service, put together."""

from contextlib import nullcontext
from datetime import timedelta

from app.auth.otp_store import OtpStore
from app.auth.service import SessionService
from app.auth.sign_in.send_steps import SignInSendSteps
from app.auth.sign_in.sending import SignInSending
from app.auth.sign_in.verifying import SignInVerifying
from app.sms.base import SmsSender
from app.users.store import UserStore


class SignInService(SignInSending, SignInSendSteps, SignInVerifying):
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
