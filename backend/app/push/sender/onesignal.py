"""The OneSignal sender: one POST per account, to the phones signed in
to it."""

import logging
import threading

from app.push.sender.message import PushMessage
from app.push.sender.onesignal_api import ONESIGNAL_URL
from app.push.sender.onesignal_phones import OneSignalPhones
from app.push.sender.onesignal_request import OneSignalRequest
from app.push.sender.outcomes import FAILED, NO_DEVICE, SENT
from app.resilience import CircuitBreaker

log = logging.getLogger(__name__)


class OneSignalPushSender(OneSignalRequest, OneSignalPhones):
    """OneSignal's REST API: one POST per account, to the phones signed in
    to it (its external id), on iOS and Android.

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

    def send(self, account_id: str, message: PushMessage) -> str:
        """Send `message` to the account's phones: SENT; NO_DEVICE when
        OneSignal knows none that shows pushes; or FAILED."""
        if not self._breaker.allow():
            return FAILED
        try:
            response = self._http().post(
                ONESIGNAL_URL,
                json=self.payload(account_id, message),
                headers={"Authorization": f"Key {self._api_key}"},
            )
        except Exception:  # noqa: BLE001 - a push must never break a request
            log.warning("OneSignal could not be reached.", exc_info=True)
            self._breaker.record_failure()
            return FAILED
        # A 4xx is about this message or the settings; OneSignal is up.
        if response.status_code >= 500:
            self._breaker.record_failure()
        else:
            self._breaker.record_success()
        try:
            answer = response.json()
        except ValueError:
            answer = {}
        if response.status_code == 200 and answer.get("id"):
            return SENT
        errors = answer.get("errors") if isinstance(answer, dict) else None
        # OneSignal answers 200 without an id when no phone of the account
        # can show a push: not a failure of the server.
        if response.status_code == 200 and errors:
            return NO_DEVICE
        log.warning(
            "OneSignal refused a push: %s %s", response.status_code, errors
        )
        return FAILED
