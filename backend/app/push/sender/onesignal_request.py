"""The HTTP client to OneSignal and the body of one push."""

from collections.abc import Collection

from app.push.sender.message import PushMessage
from app.push.sender.onesignal_api import NOTIFICATION_SOUND

# A task due now: shown through a Focus and the Scheduled Summary on iOS,
# once the app has the Time Sensitive capability (as usual without it).
TIME_SENSITIVE = {
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
        (the app opens that item with them, and the phone stacks one kind
        together), and the app's own chime on iOS.
        """
        to = (
            {"include_subscription_ids": sorted(phones)}
            if phones
            else {"include_aliases": {"external_id": [account_id]}}
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
            "thread_id": message.kind,
            "android_group": message.kind,
            "ios_interruption_level": (
                "time-sensitive"
                if message.kind in TIME_SENSITIVE
                else "active"
            ),
        }
