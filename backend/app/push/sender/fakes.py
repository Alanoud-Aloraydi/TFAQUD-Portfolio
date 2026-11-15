"""The senders without OneSignal: none set up, and the one tests read."""

from dataclasses import dataclass, field

from app.push.sender.message import PushMessage
from app.push.sender.outcomes import FAILED, NO_DEVICE, SENT


class NoPushSender:
    """No push service is set up: nothing is sent."""

    enabled = False

    def send(self, account_id: str, message: PushMessage) -> str:
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
    report as deleted apps.
    """

    enabled: bool = True
    sent: list = field(default_factory=list)
    no_device: set = field(default_factory=set)
    deleted: dict = field(default_factory=dict)
    asked: list = field(default_factory=list)

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

    def deleted_apps(self, account_id: str) -> set[str]:
        """The subscription ids in `deleted` for the account; each question
        is kept in `asked`."""
        self.asked.append(account_id)
        return {str(one) for one in self.deleted.get(account_id, ())}
