"""The OneSignal sender: one POST per account, to the phones signed in to
it, and which of an account's phones deleted the app.

OneSignal's addresses, its code for a deleted app and the sound every push
plays are here too."""

import logging
import threading
from collections.abc import Collection

from app.push.sender import FAILED, NO_DEVICE, PushMessage, SENT
from app.resilience import CircuitBreaker

log = logging.getLogger(__name__)


ONESIGNAL_URL = "https://api.onesignal.com/notifications?c=push"

# One account, by its external id, with its phones ("subscriptions").
ONESIGNAL_USER_URL = (
    "https://api.onesignal.com/apps/{app_id}/users/by/external_id/{account}"
)


def external_id(account_id: str) -> str:
    """The account as the app names it to OneSignal (OneSignal.login): the
    id the API answers, without dashes (app/users/postgres.py).
    OneSignal matches an external id letter for letter, so the dashed form
    of the same id reaches no phone and finds no user."""
    return account_id.replace("-", "")


# OneSignal's `notification_types` for a phone whose app was deleted: set by
# OneSignal itself when Apple or Google refuses the phone's token. A phone
# that only turned notifications off is 0 (its app still says so when it
# opens), so it never matches.
APP_DELETED = -10

# The app's notification sound (app/assets/sounds/), the same name the app
# gives its own reminders, so both sound the same.
NOTIFICATION_SOUND = "tafaqod_chime.wav"

# The field of a push that says how far it may interrupt on iOS.
LEVEL = "ios_interruption_level"

# A task due now: shown through a Focus and the Scheduled Summary on iOS,
# once the app has the Time Sensitive capability (as usual without it).
TIME_SENSITIVE = {
    "dose_reminder",
    "measurement_reminder",
    "appointment_reminder",
    "dose_missed",
    "measurement_missed",
    "appointment_missed",
    "dose_snoozed",
    "measurement_snoozed",
}


class OneSignalPushSender:
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

    # The client every call shares and what a push asks OneSignal to show.
    def _http(self):
        """The HTTP client to OneSignal, made once and shared by the threads;
        no call waits more than 10 seconds."""
        with self._lock:
            if self._client is None:
                import httpx

                self._client = httpx.Client(timeout=10)
            return self._client

    def payload(
        self,
        account_id: str,
        message: PushMessage,
        phones: Collection[str] = (),
    ) -> dict:
        """What OneSignal is asked to deliver, and to which phones: the
        subscriptions the account's sign-ins sent (`phones`), the way
        OneSignal's own test message reaches them; else every phone
        OneSignal ties to the account (its external id, set by the app's
        OneSignal.login). Then the title and the line (in Arabic, also under
        "en", which OneSignal requires), the kind and the item it is about
        (the app opens that item with them), the stack it joins on the
        phone (its thread, else its kind), its buttons, and the app's own
        chime on iOS.
        """
        alias = {"external_id": [external_id(account_id)]}
        to = (
            {"include_subscription_ids": sorted(phones)}
            if phones
            else {"include_aliases": alias}
        )
        thread = message.thread or message.kind
        buttons = (
            {"ios_category": message.category} if message.category else {}
        )
        return {
            "app_id": self._app_id,
            "target_channel": "push",
            **to,
            "headings": {"en": message.title, "ar": message.title},
            "contents": {"en": message.body, "ar": message.body},
            "data": {"kind": message.kind, **dict(message.target)},
            # The app copies its chime to the phone's Library/Sounds, where
            # iOS finds it; before the app has run once, iOS plays its own.
            "ios_sound": NOTIFICATION_SOUND,
            "thread_id": thread,
            "android_group": thread,
            **buttons,
            # With an underscore: OneSignal answers 400 to "time-sensitive".
            LEVEL: (
                "time_sensitive"
                if message.kind in TIME_SENSITIVE
                else "active"
            ),
        }

    def ask(self, body: dict) -> tuple[int, dict]:
        """POST one push: the status and the answer ({} when it is not a
        JSON object)."""
        response = self._http().post(
            ONESIGNAL_URL,
            json=body,
            headers={"Authorization": f"Key {self._api_key}"},
        )
        try:
            answer = response.json()
        except ValueError:
            answer = {}
        return response.status_code, answer if isinstance(answer, dict) else {}

    # Asks OneSignal about an account's phones.
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
                    app_id=self._app_id, account=external_id(account_id)
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


def _refuses_level(answer: dict) -> bool:
    """Whether OneSignal's errors are about the interruption level."""
    return "interruption level" in str(answer.get("errors")).lower()
