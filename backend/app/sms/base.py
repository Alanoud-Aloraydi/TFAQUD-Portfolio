"""The SMS sender interface.

The rest of the app sends an SMS only through `SmsSender.send`. It never knows
which provider is behind it. Two implementations are planned:

  FakeSmsSender         - this task. Development and tests. Sends nothing.
  AuthenticaSmsSender   - TFQD-12 / F01. The only code that may send a real SMS.
"""

from abc import ABC, abstractmethod


class SmsDeliveryError(Exception):
    """The provider could not deliver the message."""


class SmsSender(ABC):
    @abstractmethod
    def send(self, to: str, message: str) -> None:
        """Send `message` to the phone number `to` (international format).

        Raises SmsDeliveryError if the message could not be sent.
        """
