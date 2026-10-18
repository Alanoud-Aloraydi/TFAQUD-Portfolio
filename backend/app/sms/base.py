"""The sign-in code sender: the interface.

The rest of the app sends and checks a sign-in code only through `SmsSender`. It
never knows which provider is behind it.

Authentica makes the code (6 digits), sends it by SMS and checks it
(docs/api-contracts.md, section 8), so the interface has two jobs:

  send_code(phone)         make a code and send it to the phone number
  check_code(phone, code)  True if the code is correct, False if it is refused

What it does not do. Counting the wrong tries (3) and limiting the codes per
phone number (3 per hour) are done by our server, in the sign-in endpoints of
F01, because Authentica does not block any try.

Two implementations:

  FakeSmsSender         - development and tests. Sends nothing. Makes and checks
                          its own code, with the rules that Authentica showed.
  AuthenticaSmsSender   - the real one. The only code that may send a real SMS.
"""

from abc import ABC, abstractmethod

# The length of the code. Authentica template 5 makes a code of 6 digits.
CODE_LENGTH = 6


class SmsDeliveryError(Exception):
    """The provider could not send the code, or could not check it.

    This is not the same as a wrong code. A wrong code is the answer False of
    `check_code`. This error means that we do not know: the provider could not
    be reached, refused our key, or gave an answer we cannot trust. `status` is
    the HTTP status when there was one.
    """

    def __init__(self, message: str, status: int | None = None):
        super().__init__(message)
        self.status = status


class SmsSender(ABC):
    @abstractmethod
    def send_code(self, phone: str) -> None:
        """Make a code and send it to `phone` (international format, +966...).

        Raises SmsDeliveryError if the code could not be sent.
        """

    @abstractmethod
    def check_code(self, phone: str, code: str) -> bool:
        """Say whether `code` is the correct, valid and unused code for `phone`.

        Returns False for a wrong, expired or already used code (the provider
        gives the same answer for all of them). Raises SmsDeliveryError if the
        provider could not decide.
        """
