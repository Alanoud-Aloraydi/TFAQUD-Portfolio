"""Senders of push notifications to Apple (APNs).

Apple delivers a push only to an app signed with a paid Apple Developer
account that has the Push Notifications capability. Until the team has one,
the server uses `NoPushSender`, which sends nothing. With the account, set
PUSH_BACKEND=apns and the APNS_* settings (see README.md), and the same code
starts sending.
"""

import logging
import time
from dataclasses import dataclass, field
from typing import Protocol

log = logging.getLogger(__name__)

# What a send can end in.
SENT = "sent"
GONE = "gone"  # Apple says the token is no longer valid: forget it.
FAILED = "failed"  # Anything else; the token is kept for the next time.

_HOSTS = {
    "sandbox": "https://api.sandbox.push.apple.com",
    "production": "https://api.push.apple.com",
}

# Apple accepts a provider token for one hour; a new one is made before.
_TOKEN_SECONDS = 50 * 60


@dataclass(frozen=True)
class PushMessage:
    """What the phone shows: a title and a line. `kind` tells the app what
    it is about (an invitation, a request, an answer)."""

    title: str
    body: str
    kind: str


class PushSender(Protocol):
    enabled: bool

    def send(self, token: str, message: PushMessage) -> str:
        """Send to one phone; answer SENT, GONE or FAILED."""


class NoPushSender:
    """No push service is set up: nothing is sent."""

    enabled = False

    def send(self, token: str, message: PushMessage) -> str:
        return FAILED


@dataclass
class RecordingPushSender:
    """For tests: keeps what would be sent. Tokens in `gone` answer GONE."""

    enabled: bool = True
    sent: list = field(default_factory=list)
    gone: set = field(default_factory=set)

    def send(self, token: str, message: PushMessage) -> str:
        if token in self.gone:
            return GONE
        self.sent.append((token, message))
        return SENT

    def to(self, token: str) -> list:
        return [message for sent, message in self.sent if sent == token]


class ApnsPushSender:
    """Apple's push service over HTTP/2, signed with the team's .p8 key.

    Apple's provider API: one POST per phone to /3/device/<token>, with a
    short JWT (ES256) made from the key id, the team id and the key.
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
    ):
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

    def _http(self):
        if self._client is None:
            import httpx

            self._client = httpx.Client(http2=True, timeout=10)
        return self._client

    def _provider_token(self) -> str:
        now = time.time()
        if self._token is None or now - self._token_made > _TOKEN_SECONDS:
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
        return {
            "aps": {
                "alert": {"title": message.title, "body": message.body},
                "sound": "default",
                # The phone stacks the notifications of one kind together.
                "thread-id": message.kind,
            },
            "kind": message.kind,
        }

    def send(self, token: str, message: PushMessage) -> str:
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
            return FAILED
        if response.status_code == 200:
            return SENT
        reason = ""
        try:
            reason = response.json().get("reason", "")
        except ValueError:
            pass
        if response.status_code == 410 or reason in (
            "BadDeviceToken",
            "Unregistered",
            "DeviceTokenNotForTopic",
        ):
            return GONE
        log.warning(
            "Apple push refused: %s %s", response.status_code, reason
        )
        return FAILED
