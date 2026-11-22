"""The HTTP client to OneSignal and the body of one push."""

from collections.abc import Collection

from app.push.sender.message import PushMessage
from app.push.sender.onesignal_api import NOTIFICATION_SOUND, ONESIGNAL_URL
from app.push.sender.onesignal_api import external_id

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


class OneSignalRequest:
    """The client every call shares and what a push asks OneSignal to show."""

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
