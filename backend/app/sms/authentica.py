"""The real sign-in code sender: Authentica (https://api.authentica.sa/api/v2).

Authentica makes the 6-digit code, sends it by SMS (Arabic text), keeps it
for the time set in its dashboard and checks it. Each call has a time limit
and goes through the circuit breaker; the JSON POST never follows a
redirect, so the key never goes to another address."""

import http.client
import json
import logging
import urllib.error
import urllib.request

from app.config.values import ConfigError
from app.resilience import CircuitBreaker
from app.sms.authentica_keys import read_balance
from app.sms.base import SmsDeliveryError, SmsSender


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    """Never follow a redirect: the key would go to the next address too."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        """Refuse every redirect."""
        return None


opener = urllib.request.build_opener(_NoRedirect)


def _parse_json(raw: bytes):
    """The JSON of an answer, or None when it cannot be read."""
    try:
        return json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, ValueError):
        return None


def urllib_post(url: str, headers: dict, body: dict, timeout: float):
    """POST `body` as JSON. Returns (HTTP status, parsed JSON or None).

    A 4xx or 5xx answer is returned, not raised: it carries a status that the
    caller reads. A network problem is raised (OSError, HTTPException).
    """
    # The body as JSON, with the caller's headers (the key).
    request = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        method="POST",
        headers={
            **headers,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    # Never follow a redirect (`opener`); a 4xx or 5xx comes back as its
    # status.
    try:
        with opener.open(request, timeout=timeout) as response:
            return response.status, _parse_json(response.read())
    except urllib.error.HTTPError as error:
        with error:
            return error.code, _parse_json(error.read())


def urllib_get(url: str, headers: dict, timeout: float):
    """GET `url`, the same way: (HTTP status, parsed JSON or None), with a
    4xx or 5xx returned and a network problem raised."""
    request = urllib.request.Request(
        url, method="GET", headers={**headers, "Accept": "application/json"}
    )
    try:
        with opener.open(request, timeout=timeout) as response:
            return response.status, _parse_json(response.read())
    except urllib.error.HTTPError as error:
        with error:
            return error.code, _parse_json(error.read())


logger = logging.getLogger(__name__)


def json_field(body, name: str):
    """One field of a JSON object, or None when the body is not an object."""
    return body.get(name) if isinstance(body, dict) else None


DEFAULT_BASE_URL = "https://api.authentica.sa/api/v2"

DEFAULT_TEMPLATE_ID = 5

DEFAULT_TIMEOUT_SECONDS = 10.0


class AuthenticaSmsSender(SmsSender):
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
        get=None,
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
        self._get = get or urllib_get

    def balance(self) -> float | None:
        """The points left on this key's account; None when unknown."""
        return read_balance(
            self._get, self._base_url, self._api_key, self._timeout
        )

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

    # Posts one call and reads the answer, or raises `SmsDeliveryError`.
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
