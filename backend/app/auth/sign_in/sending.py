"""Sending a sign-in code within the limits."""

import math
from datetime import timedelta

from app.auth.otp_store import AttemptsExhausted, SendRules
from app.auth.sign_in.results import CodeSent
from app.errors import NotFound, TooManyRequests

# The codes to one phone number count for 24 hours (and only since its last
# accepted code); the codes of one device or one IP for one hour.
SEND_WINDOW = timedelta(hours=24)
ASKER_WINDOW = timedelta(hours=1)


class SignInSending:
    """Sends a code: judged, reserved, sent, recorded."""

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
