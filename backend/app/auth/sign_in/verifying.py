"""Checking a typed code and finishing the sign-in."""

from app import metrics
from app.auth.sign_in.results import SignInResult
from app.errors import ServiceUnavailable, TooManyRequests, ValidationFailed
from app.sms.base import SmsDeliveryError


class SignInVerifying:
    """Checks a code and starts the session."""

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
