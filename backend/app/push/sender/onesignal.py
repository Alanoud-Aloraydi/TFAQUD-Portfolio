"""The OneSignal sender: one POST per account, to the phones signed in
to it."""

from collections.abc import Collection

import logging
import threading

from app.push.sender.message import PushMessage
from app.push.sender.onesignal_phones import OneSignalPhones
from app.push.sender.onesignal_request import LEVEL, OneSignalRequest
from app.push.sender.outcomes import FAILED, NO_DEVICE, SENT
from app.resilience import CircuitBreaker

log = logging.getLogger(__name__)


class OneSignalPushSender(OneSignalRequest, OneSignalPhones):
    """OneSignal's REST API: one POST per account, to the phones signed in
    to it (the subscriptions its sign-ins sent, else its external id), on
    iOS and Android.

    After 3 sends in a row with no answer or a 5xx, OneSignal is not called
    for a minute (app/resilience.py): each send answers FAILED at once, so a
    scan with many accounts does not wait 10 seconds for each.
    """

    enabled = True

    def __init__(
        self,
        *,
        app_id: str,
        api_key: str,
        client=None,
        breaker: CircuitBreaker | None = None,
    ):
        """Keep the OneSignal app's id and its App API key, and make the
        circuit breaker."""
        self._app_id = app_id
        self._api_key = api_key
        self._client = client
        self._breaker = breaker or CircuitBreaker("onesignal")
        # Pushes go out from two background threads (app/background.py).
        self._lock = threading.Lock()

    def send(
        self,
        account_id: str,
        message: PushMessage,
        phones: Collection[str] = (),
    ) -> str:
        """Send `message` to the account's phones: SENT; NO_DEVICE when
        OneSignal knows none that shows pushes; or FAILED."""
        if not self._breaker.allow():
            return FAILED
        body = self.payload(account_id, message, phones)
        try:
            status, answer = self.ask(body)
            if status == 400 and _refuses_level(answer):
                # The level is an extra: no push is lost for it.
                log.warning(
                    "OneSignal refused the interruption level %r; the "
                    "push goes without it.", body.pop(LEVEL, None)
                )
                status, answer = self.ask(body)
        except Exception:  # noqa: BLE001 - a push must never break a request
            log.warning("OneSignal could not be reached.", exc_info=True)
            self._breaker.record_failure()
            return FAILED
        # A 4xx is about this message or the settings; OneSignal is up.
        if status >= 500:
            self._breaker.record_failure()
        else:
            self._breaker.record_success()
        if status == 200 and answer.get("id"):
            return SENT
        errors = answer.get("errors")
        # OneSignal answers 200 without an id when no phone of the account
        # can show a push: not a failure of the server.
        if status == 200 and errors:
            return NO_DEVICE
        log.warning("OneSignal refused a push: %s %s", status, errors)
        return FAILED


def _refuses_level(answer: dict) -> bool:
    """Whether OneSignal's errors are about the interruption level."""
    return "interruption level" in str(answer.get("errors")).lower()
