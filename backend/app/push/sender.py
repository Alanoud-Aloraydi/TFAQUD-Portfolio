"""Senders of push notifications, through OneSignal (iOS and Android).

OneSignal knows each phone by the account signed in on it: the app calls
OneSignal's `login` with the account's id (its "external id") and `logout`
at sign-out. So the server sends to an account, never to a phone token.
Without PUSH_BACKEND=onesignal and its two settings (README.md), the server
uses `NoPushSender`, which sends nothing.
"""

import logging
import threading
from dataclasses import dataclass, field
from typing import Protocol

from app.resilience import CircuitBreaker

log = logging.getLogger(__name__)

# What a send can end in.
SENT = "sent"
# OneSignal knows no phone of the account that can show a push (it never
# signed in on the new app, or it refused notifications).
NO_DEVICE = "no_device"
FAILED = "failed"  # Anything else.

ONESIGNAL_URL = "https://api.onesignal.com/notifications?c=push"

# The app's notification sound (app/assets/sounds/), the same name the app
# gives its own reminders, so both sound the same.
NOTIFICATION_SOUND = "tafaqod_chime.wav"


@dataclass(frozen=True)
class PushMessage:
    """What the phone shows: a title and a line. `kind` tells the app what
    it is about (an invitation, a request, an answer)."""

    title: str
    body: str
    kind: str


class PushSender(Protocol):
    """What every push sender has: `enabled`, and `send` to one account."""
    enabled: bool

    def send(self, account_id: str, message: PushMessage) -> str:
        """Send to the account's phones; answer SENT, NO_DEVICE or FAILED.
        """


class NoPushSender:
    """No push service is set up: nothing is sent."""

    enabled = False

    def send(self, account_id: str, message: PushMessage) -> str:
        """Send nothing."""
        return FAILED


@dataclass
class RecordingPushSender:
    """For tests: keeps what would be sent, by account id. Accounts in
    `no_device` answer NO_DEVICE (no phone of theirs shows pushes).
    """

    enabled: bool = True
    sent: list = field(default_factory=list)
    no_device: set = field(default_factory=set)

    def send(self, account_id: str, message: PushMessage) -> str:
        """Keep the message, or answer NO_DEVICE for an account in
        `no_device`.
        """
        if account_id in self.no_device:
            return NO_DEVICE
        self.sent.append((account_id, message))
        return SENT

    def to(self, account_id) -> list:
        """The messages kept for one account (its id, as text or UUID)."""
        return [
            message for sent, message in self.sent if sent == str(account_id)
        ]


class OneSignalPushSender:
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
