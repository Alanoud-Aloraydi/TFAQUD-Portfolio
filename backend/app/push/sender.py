"""Senders of push notifications: a push message, what every sender can
do and what a send can end in, and the senders without OneSignal (none set
up, and the one tests read).

OneSignal knows each phone by the account signed in on it: the app calls
OneSignal's `login` with the account's id (its "external id"), so a push
is addressed to an account, never to a device token."""

from collections.abc import Collection
from dataclasses import dataclass, field
from typing import Protocol


SENT = "sent"

# OneSignal knows no phone of the account that can show a push (it never
# signed in on the new app, or it refused notifications).
NO_DEVICE = "no_device"

FAILED = "failed"  # Anything else.


@dataclass(frozen=True)
class PushMessage:
    """What the phone shows: a title and a line. `kind` tells the app what
    it is about (an invitation, a request, an answer), and `target` which
    item, as pairs of text (app/push/notify.py), so a tap opens it.

    `thread` stacks pushes together on the phone (the kind when None), and
    `category` is the iOS category whose buttons the push shows («ذكّرني
    لاحقًا» on a reminder), registered by the app."""

    title: str
    body: str
    kind: str
    target: tuple[tuple[str, str], ...] = ()
    thread: str | None = None
    category: str | None = None


class PushSender(Protocol):
    """What every push sender has: `enabled`, `send` to one account, and
    `deleted_apps` of one account."""
    enabled: bool

    def send(
        self,
        account_id: str,
        message: PushMessage,
        phones: Collection[str] = (),
    ) -> str:
        """Send to the account's phones: `phones` (their OneSignal
        subscriptions) when known, else every phone OneSignal ties to the
        account. Answer SENT, NO_DEVICE or FAILED."""

    def deleted_apps(self, account_id: str) -> set[str]:
        """The OneSignal subscription ids of the account's phones whose app
        was deleted; empty when unsure."""


class NoPushSender:
    """No push service is set up: nothing is sent."""

    enabled = False

    def send(
        self,
        account_id: str,
        message: PushMessage,
        phones: Collection[str] = (),
    ) -> str:
        """Send nothing."""
        return FAILED

    def deleted_apps(self, account_id: str) -> set[str]:
        """Knows of no phone."""
        return set()


@dataclass
class RecordingPushSender:
    """For tests: keeps what would be sent, by account id. Accounts in
    `no_device` answer NO_DEVICE (no phone of theirs shows pushes), and
    `deleted` holds, by account id, the subscription ids OneSignal would
    report as deleted apps. `phones` keeps the subscriptions each send was
    addressed to, by account id.
    """

    enabled: bool = True
    sent: list = field(default_factory=list)
    no_device: set = field(default_factory=set)
    deleted: dict = field(default_factory=dict)
    asked: list = field(default_factory=list)
    phones: dict = field(default_factory=dict)

    def send(
        self,
        account_id: str,
        message: PushMessage,
        phones: Collection[str] = (),
    ) -> str:
        """Keep the message, or answer NO_DEVICE for an account in
        `no_device`.
        """
        self.phones[account_id] = set(phones)
        if account_id in self.no_device:
            return NO_DEVICE
        self.sent.append((account_id, message))
        return SENT

    def to(self, account_id) -> list:
        """The messages kept for one account (its id, as text or UUID)."""
        return [
            message for sent, message in self.sent if sent == str(account_id)
        ]

    def deleted_apps(self, account_id: str) -> set[str]:
        """The subscription ids in `deleted` for the account; each question
        is kept in `asked`."""
        self.asked.append(account_id)
        return {str(one) for one in self.deleted.get(account_id, ())}
