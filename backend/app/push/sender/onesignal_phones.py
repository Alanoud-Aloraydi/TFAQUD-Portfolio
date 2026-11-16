"""Which of an account's phones deleted the app, as OneSignal knows."""

import logging

from app.push.sender.onesignal_api import APP_DELETED, ONESIGNAL_USER_URL

log = logging.getLogger(__name__)


class OneSignalPhones:
    """Asks OneSignal about an account's phones."""

    def deleted_apps(self, account_id: str) -> set[str]:
        """Ask OneSignal for the account's phones and answer the ids of those
        whose app was deleted (`APP_DELETED`). Any doubt (no answer, an
        error, an account OneSignal does not know) answers none, so no
        sign-in ends by mistake."""
        if not self._breaker.allow():
            return set()
        try:
            response = self._http().get(
                ONESIGNAL_USER_URL.format(
                    app_id=self._app_id, account=account_id
                ),
                headers={"Authorization": f"Key {self._api_key}"},
            )
        except Exception:  # noqa: BLE001 - a push must never break a request
            log.warning("OneSignal could not be reached.", exc_info=True)
            self._breaker.record_failure()
            return set()
        if response.status_code >= 500:
            self._breaker.record_failure()
            return set()
        self._breaker.record_success()
        if response.status_code != 200:
            return set()
        try:
            phones = response.json().get("subscriptions") or []
        except (ValueError, AttributeError):
            return set()
        return {
            str(phone["id"])
            for phone in phones
            if isinstance(phone, dict)
            and phone.get("id")
            and phone.get("notification_types") == APP_DELETED
        }
