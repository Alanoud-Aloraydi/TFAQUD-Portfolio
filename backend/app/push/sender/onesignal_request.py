"""The HTTP client to OneSignal and the body of one push."""

from app.push.sender.message import PushMessage
from app.push.sender.onesignal_api import NOTIFICATION_SOUND


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

    def payload(self, account_id: str, message: PushMessage) -> dict:
        """What OneSignal is asked to deliver: the title and the line (in
        Arabic, also under "en", which OneSignal requires), the kind (the
        app opens the right page with it, and the phone stacks one kind
        together), and the app's own chime on iOS.
        """
        return {
            "app_id": self._app_id,
            "target_channel": "push",
            "include_aliases": {"external_id": [account_id]},
            "headings": {"en": message.title, "ar": message.title},
            "contents": {"en": message.body, "ar": message.body},
            "data": {"kind": message.kind},
            # The app copies its chime to the phone's Library/Sounds, where
            # iOS finds it; before the app has run once, iOS plays its own.
            "ios_sound": NOTIFICATION_SOUND,
            "thread_id": message.kind,
            "android_group": message.kind,
        }
