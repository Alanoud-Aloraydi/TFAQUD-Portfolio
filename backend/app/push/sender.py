"""Senders of push notifications to Apple (APNs).

Apple delivers a push only to an app signed with a paid Apple Developer
account that has the Push Notifications capability. Until the team has one,
the server uses `NoPushSender`, which sends nothing. With the account, set
PUSH_BACKEND=apns and the APNS_* settings (see README.md), and the same code
starts sending.
"""

import logging
import threading
import time
from dataclasses import dataclass, field
from typing import Protocol

from app.resilience import CircuitBreaker

log = logging.getLogger(__name__)

# What a send can end in.
SENT = "sent"
# Apple says the token is wrong for this app (a sandbox token sent to the
# production server, say): forget the token, keep the sign-in.
GONE = "gone"
# Apple says the token is no longer active (410), which is what deleting the
# app from the phone leads to: forget the token and sign its session out.
UNREGISTERED = "unregistered"
FAILED = "failed"  # Anything else; the token is kept for the next time.

_HOSTS = {
    "sandbox": "https://api.sandbox.push.apple.com",
    "production": "https://api.push.apple.com",
}

# Apple accepts a provider token for one hour; a new one is made before.
_TOKEN_SECONDS = 50 * 60

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
    """What every push sender has: `enabled`, and `send` to one phone."""
    enabled: bool

    def send(self, token: str, message: PushMessage) -> str:
        """Send to one phone; answer SENT, GONE, UNREGISTERED or FAILED."""


class NoPushSender:
    """No push service is set up: nothing is sent."""

    enabled = False

    def send(self, token: str, message: PushMessage) -> str:
        """Send nothing."""
        return FAILED


@dataclass
class RecordingPushSender:
    """For tests: keeps what would be sent. Tokens in `gone` answer GONE,
    and tokens in `deleted_apps` answer UNREGISTERED (the app was deleted).
    """

    enabled: bool = True
    sent: list = field(default_factory=list)
    gone: set = field(default_factory=set)
    deleted_apps: set = field(default_factory=set)

    def send(self, token: str, message: PushMessage) -> str:
        """Keep the message, or answer GONE or UNREGISTERED for a token in
        `gone` or `deleted_apps`.
        """
        if token in self.gone:
            return GONE
        if token in self.deleted_apps:
            return UNREGISTERED
        self.sent.append((token, message))
        return SENT

    def to(self, token: str) -> list:
        """The messages kept for one token."""
        return [message for sent, message in self.sent if sent == token]


class ApnsPushSender:
    """Apple's push service over HTTP/2, signed with the team's .p8 key.

    Apple's provider API: one POST per phone to /3/device/<token>, with a
    short JWT (ES256) made from the key id, the team id and the key.

    After 3 sends in a row with no answer or a 5xx, Apple is not called for
    a minute (app/resilience.py): each send answers FAILED at once, so a
    scan with many phones does not wait 10 seconds per phone.
    """

    enabled = True

    def __init__(
        self,
        *,
        key_id: str,
        team_id: str,
        bundle_id: str,
        private_key: str,
        environment: str = "sandbox",
        client=None,
        breaker: CircuitBreaker | None = None,
    ):
        """Keep the team's key and ids, choose Apple's sandbox or production
        server, and make the circuit breaker.
        """
        if environment not in _HOSTS:
            raise ValueError("environment must be sandbox or production")
        self._key_id = key_id
        self._team_id = team_id
        self._bundle_id = bundle_id
        self._private_key = private_key
        self._host = _HOSTS[environment]
        self._client = client
        self._token: str | None = None
        self._token_made = 0.0
        self._breaker = breaker or CircuitBreaker("apns")
        # Pushes go out from two background threads (app/background.py).
        self._lock = threading.Lock()

    def _http(self):
        """The HTTP/2 client to Apple, made once and shared by the threads."""
        with self._lock:
            if self._client is None:
                import httpx

                self._client = httpx.Client(http2=True, timeout=10)
            return self._client

    def _provider_token(self) -> str:
        """The signed token Apple asks for, made again before it is an hour
        old.
        """
        # One token for every thread, made again before Apple's hour ends.
        with self._lock:
            now = time.time()
            if (
                self._token is None
                or now - self._token_made > _TOKEN_SECONDS
            ):
                import jwt

                self._token = jwt.encode(
                    {"iss": self._team_id, "iat": int(now)},
                    self._private_key,
                    algorithm="ES256",
                    headers={"kid": self._key_id},
                )
                self._token_made = now
            return self._token

    def payload(self, message: PushMessage) -> dict:
        """What Apple delivers to the phone: the title, the line, our sound,
        and the kind (so the phone groups them).
        """
        return {
            "aps": {
                "alert": {"title": message.title, "body": message.body},
                # The app's own soft chime; the app copies it to the
                # phone's Library/Sounds, where iOS finds it. Before the
                # app has run once, iOS plays its default sound instead.
                "sound": NOTIFICATION_SOUND,
                # The phone stacks the notifications of one kind together.
                "thread-id": message.kind,
            },
            "kind": message.kind,
        }

    def send(self, token: str, message: PushMessage) -> str:
        """Send `message` to one phone: SENT; UNREGISTERED when the token is
        no longer active (the app was deleted); GONE when the token is wrong
        for this app; or FAILED (the token is kept).
        """
        if not self._breaker.allow():
            return FAILED
        # One POST per phone, signed with the provider token.
        try:
            response = self._http().post(
                f"{self._host}/3/device/{token}",
                json=self.payload(message),
                headers={
                    "authorization": f"bearer {self._provider_token()}",
                    "apns-topic": self._bundle_id,
                    "apns-push-type": "alert",
                    "apns-priority": "10",
                },
            )
        except Exception:  # noqa: BLE001 - a push must never break a request
            log.warning("Apple push could not be reached.", exc_info=True)
            self._breaker.record_failure()
            return FAILED
        # A 4xx is about this phone or this message; Apple itself is up.
        if response.status_code >= 500:
            self._breaker.record_failure()
        else:
            self._breaker.record_success()
        if response.status_code == 200:
            return SENT
        # Apple says why. 410 (Unregistered, ExpiredToken) is final: the token
        # is no longer active, as after the app is deleted. A token that is
        # wrong for this app is GONE, but says nothing about the app: a
        # BadDeviceToken is often a sandbox token sent to the production
        # server. Anything else is FAILED and the token is kept.
        reason = ""
        try:
            reason = response.json().get("reason", "")
        except ValueError:
            pass
        if response.status_code == 410 or reason == "Unregistered":
            return UNREGISTERED
        if reason in ("BadDeviceToken", "DeviceTokenNotForTopic"):
            return GONE
        log.warning(
            "Apple push refused: %s %s", response.status_code, reason
        )
        return FAILED
