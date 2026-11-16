"""The real sign-in code sender: Authentica (https://api.authentica.sa/api/v2).

Authentica makes the 6-digit code with template 5, sends it by SMS (Arabic
text), keeps it for the time set in its dashboard (300 seconds) and checks it.
This file only makes the two calls and reads the answers.

The HTTP call is a small function (`transport`) that can be replaced. Tests
give a fake one, so no test opens a network connection. The default one uses
only the standard library.

Nothing here writes the key, the phone number or the code to a log or to an
error message."""

from app.config import ConfigError
from app.resilience import CircuitBreaker
from app.sms.authentica_calls import AuthenticaCalls, json_field
from app.sms.base import SmsSender
from app.sms.http_post import urllib_post

DEFAULT_BASE_URL = "https://api.authentica.sa/api/v2"
DEFAULT_TEMPLATE_ID = 5
DEFAULT_TIMEOUT_SECONDS = 10.0


class AuthenticaSmsSender(AuthenticaCalls, SmsSender):
    """Sends and checks sign-in codes through Authentica's two calls, send-otp
    and verify-otp.
    """
    def __init__(
        self,
        api_key: str,
        *,
        base_url: str = DEFAULT_BASE_URL,
        template_id: int = DEFAULT_TEMPLATE_ID,
        timeout: float = DEFAULT_TIMEOUT_SECONDS,
        transport=None,
        breaker: CircuitBreaker | None = None,
    ):
        """Check the key and the https address, and keep the template, the time
        limit, the HTTP function and the circuit breaker.
        """
        if not api_key:
            raise ConfigError(
                "AUTHENTICA_API_KEY is required to use Authentica."
            )
        if not base_url.startswith("https://"):
            raise ConfigError(
                "The Authentica address must start with https://"
            )
        self._api_key = api_key
        self._base_url = base_url.rstrip("/")
        self._template_id = template_id
        self._timeout = timeout
        self._transport = transport or urllib_post
        self._breaker = breaker or CircuitBreaker("authentica")

    def send_code(self, phone: str) -> None:
        """Ask Authentica to make a code and send it to `phone` by SMS; raise
        SmsDeliveryError unless it confirms.
        """
        status, body = self._post(
            "send-otp",
            {
                "method": "sms",
                "phone": phone,
                "template_id": self._template_id,
            },
        )
        if status == 200 and json_field(body, "success") is True:
            return
        raise self._error("send-otp", status)

    def check_code(self, phone: str, code: str) -> bool:
        """Ask Authentica whether `code` is right for `phone`: True, False for
        any refused code, or SmsDeliveryError when it cannot decide.
        """
        status, body = self._post("verify-otp", {"phone": phone, "otp": code})
        if status == 200 and json_field(body, "status") is True:
            return True
        refused = status == 200 and json_field(body, "status") is False
        if status == 422 or refused:
            return False
        raise self._error("verify-otp", status)
