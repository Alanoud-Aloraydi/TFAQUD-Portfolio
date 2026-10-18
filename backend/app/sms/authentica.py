"""The real sign-in code sender: Authentica (https://api.authentica.sa/api/v2).

Authentica makes the 6-digit code with template 5, sends it by SMS (Arabic text),
keeps it for the time set in its dashboard (300 seconds) and checks it. This file
only makes the two calls and reads the answers.

What the tests of TFQD-12 found out (docs/api-contracts.md, section 8), and how
this file uses it:

  - The key goes in the header `X-Authorization`.
  - `send-otp` answers 200 with `success: true`. We send no `otp` field, so
    Authentica makes the code itself.
  - `verify-otp` answers 200 with `status: true` for a correct code. It answers
    422 for every refused code: wrong, wrong length, expired, used. One answer,
    so `check_code` returns False for all of them.
  - We decide from the HTTP status and the `success` or `status` field, never
    from the text of the message.
  - Anything else (401 for a wrong key, 429 for too many calls, 5xx, no answer, an
    answer we do not know) is not a decision about the code. It raises
    `SmsDeliveryError`, so that it is never counted as a wrong try.

The HTTP call is a small function (`transport`) that can be replaced. Tests give a
fake one, so no test opens a network connection. The default one uses only the
standard library.

Nothing here writes the key, the phone number or the code to a log or to an error
message.
"""

import http.client
import json
import logging
import urllib.error
import urllib.request

from app.config import ConfigError
from app.sms.base import SmsDeliveryError, SmsSender

logger = logging.getLogger(__name__)

DEFAULT_BASE_URL = "https://api.authentica.sa/api/v2"
DEFAULT_TEMPLATE_ID = 5
DEFAULT_TIMEOUT_SECONDS = 10.0


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    """Never follow a redirect: the key would be sent to the next address too."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


_opener = urllib.request.build_opener(_NoRedirect)


def _parse_json(raw: bytes):
    try:
        return json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, ValueError):
        return None


def urllib_post(url: str, headers: dict, body: dict, timeout: float):
    """POST `body` as JSON. Returns (HTTP status, parsed JSON or None).

    A 4xx or 5xx answer is returned, not raised: it carries a status that the
    caller reads. A network problem is raised (OSError, HTTPException).
    """
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
    try:
        with _opener.open(request, timeout=timeout) as response:
            return response.status, _parse_json(response.read())
    except urllib.error.HTTPError as error:
        with error:
            return error.code, _parse_json(error.read())


def _field(body, name: str):
    return body.get(name) if isinstance(body, dict) else None


class AuthenticaSmsSender(SmsSender):
    def __init__(
        self,
        api_key: str,
        *,
        base_url: str = DEFAULT_BASE_URL,
        template_id: int = DEFAULT_TEMPLATE_ID,
        timeout: float = DEFAULT_TIMEOUT_SECONDS,
        transport=None,
    ):
        if not api_key:
            raise ConfigError("AUTHENTICA_API_KEY is required to use Authentica.")
        if not base_url.startswith("https://"):
            raise ConfigError("The Authentica address must start with https://")
        self._api_key = api_key
        self._base_url = base_url.rstrip("/")
        self._template_id = template_id
        self._timeout = timeout
        self._transport = transport or urllib_post

    def send_code(self, phone: str) -> None:
        status, body = self._post(
            "send-otp",
            {"method": "sms", "phone": phone, "template_id": self._template_id},
        )
        if status == 200 and _field(body, "success") is True:
            return
        raise self._error("send-otp", status)

    def check_code(self, phone: str, code: str) -> bool:
        status, body = self._post("verify-otp", {"phone": phone, "otp": code})
        if status == 200 and _field(body, "status") is True:
            return True
        if status == 422 or (status == 200 and _field(body, "status") is False):
            return False
        raise self._error("verify-otp", status)

    def _post(self, call: str, body: dict):
        try:
            status, parsed = self._transport(
                f"{self._base_url}/{call}",
                {"X-Authorization": self._api_key},
                body,
                self._timeout,
            )
        except (OSError, http.client.HTTPException) as error:
            # The type only: the text of the error could hold the address.
            logger.warning("Authentica %s: no answer (%s)", call, type(error).__name__)
            raise SmsDeliveryError(
                f"Authentica did not answer {call} ({type(error).__name__})."
            ) from None
        logger.info("Authentica %s: HTTP %s", call, status)
        return status, parsed

    @staticmethod
    def _error(call: str, status: int) -> SmsDeliveryError:
        message = f"Authentica answered {call} with HTTP {status}, which cannot be used."
        if status == 401:
            message += " Check AUTHENTICA_API_KEY."
        return SmsDeliveryError(message, status=status)
