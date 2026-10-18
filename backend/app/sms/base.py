"""The SMS sender interface.

The rest of the app sends an SMS only through `SmsSender.send`. It never knows
which provider is behind it. Two implementations are planned:

  FakeSmsSender         - this task. Development and tests. Sends nothing.
  AuthenticaSmsSender   - F01 (TFQD-13). The only code that may send a real SMS.

F01 changes this interface. Authentica makes and checks the sign-in code
(docs/api-contracts.md, section 8), so the interface will have two jobs: send a
code to a phone number, and check a code. The fake will make and check its own.
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
