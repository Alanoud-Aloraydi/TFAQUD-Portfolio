"""One call to Authentica and its answer, with the circuit breaker.

What the tests of TFQD-12 found out (docs/api-contracts.md, section 8), and how
these calls use it:

  - The key goes in the header `X-Authorization`.
  - `send-otp` answers 200 with `success: true`. We send no `otp` field, so
    Authentica makes the code itself.
  - `verify-otp` answers 200 with `status: true` for a correct code. It answers
    422 for every refused code: wrong, wrong length, expired, used. One answer,
    so `check_code` returns False for all of them.
  - We decide from the HTTP status and the `success` or `status` field, never
    from the text of the message.
  - Anything else (401 for a wrong key, 429 for too many calls, 5xx, no
    answer, an answer we do not know) is not a decision about the code. It
    raises `SmsDeliveryError`, so that it is never counted as a wrong try.
  - After 3 calls in a row with no answer, a 5xx or a 429, Authentica is
    not called for a minute (app/resilience.py): sign-in answers "try
    again" at once instead of after 10 seconds each.
"""

import http.client
import logging

from app.sms.base import SmsDeliveryError

logger = logging.getLogger(__name__)


def json_field(body, name: str):
    """One field of a JSON object, or None when the body is not an object."""
    return body.get(name) if isinstance(body, dict) else None


class AuthenticaCalls:
    """Posts one call and reads the answer, or raises `SmsDeliveryError`."""

    def _post(self, call: str, body: dict):
        """Make one call to Authentica through the circuit breaker, and answer
        its HTTP status and JSON.
        """
        if not self._breaker.allow():
            raise SmsDeliveryError(
                f"Authentica failed several times; {call} was not called.",
                not_sent=True,
            )
        try:
            status, parsed = self._transport(
                f"{self._base_url}/{call}",
                {"X-Authorization": self._api_key},
                body,
                self._timeout,
            )
        except (OSError, http.client.HTTPException) as error:
            # The type only: the text of the error could hold the address.
            logger.warning(
                "Authentica %s: no answer (%s)", call, type(error).__name__
            )
            self._breaker.record_failure()
            raise SmsDeliveryError(
                f"Authentica did not answer {call} ({type(error).__name__})."
            ) from None
        logger.info("Authentica %s: HTTP %s", call, status)
        # Sick: a server error, or too many calls. A 401 (wrong key) or a
        # 422 (wrong code) is an answer, so Authentica is up.
        if status >= 500 or status == 429:
            self._breaker.record_failure()
        else:
            self._breaker.record_success()
        return status, parsed

    @staticmethod
    def _error(call: str, status: int) -> SmsDeliveryError:
        """The error for an answer that cannot be used, pointing at the key on
        a 401.
        """
        message = (
            f"Authentica answered {call} with HTTP {status}, "
            "which cannot be used."
        )
        if status == 401:
            message += " Check AUTHENTICA_API_KEY."
        return SmsDeliveryError(message, status=status)
