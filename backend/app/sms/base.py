"""The sign-in code sender: the interface.

The application sends and verifies codes through SmsSender.

Authentica makes the code (6 digits), sends it by SMS and checks it
(docs/api-contracts.md, section 8), so the interface has two jobs:

  send_code(phone)         make a code and send it to the phone number
  check_code(phone, code)  True if the code is correct, False if it is refused

What it does not do. Counting the wrong tries (3) and limiting the codes per
phone number (3 per hour) are done by our server, in the sign-in endpoints of
F01, because Authentica does not block any try.

Two implementations:

  FakeSmsSender         - isolated tests; no messages leave the process.
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

    @property
    def delivery_rejected(self) -> bool:
        """A definite client rejection permits releasing delivery quota."""
        return self.status in {400, 401, 403, 404, 422, 429}


class SmsSender(ABC):
    @abstractmethod
    def send_code(self, phone: str) -> None:
        """Make a code and send it to `phone` (international format, +966...).

        Raises SmsDeliveryError if the code could not be sent.
        """

    @abstractmethod
    def check_code(self, phone: str, code: str) -> bool:
        """Verify an unused code for the given phone number.

        Returns False for a wrong, expired or already used code (the provider
        gives the same answer for all of them). Raises SmsDeliveryError if the
        provider could not decide.
        """
