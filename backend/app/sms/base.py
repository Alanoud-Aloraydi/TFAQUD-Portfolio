"""The sign-in code sender: the interface, and the demo accounts' sign-in.

Authentica makes the code (6 digits), sends it by SMS and checks it
(docs/api-contracts.md, section 8). The demo numbers are made up, so with
DEMO_SIGN_IN_CODE set they get no SMS at all and sign in with that code."""

import hmac
from abc import ABC, abstractmethod
from collections.abc import Iterable


# The length of the code. Authentica template 5 makes a code of 6 digits.
CODE_LENGTH = 6


class SmsDeliveryError(Exception):
    """The provider could not send the code, or could not check it.

    This is not the same as a wrong code. A wrong code is the answer False of
    `check_code`. This error means that we do not know: the provider could not
    be reached, refused our key, or gave an answer we cannot trust. `status` is
    the HTTP status when there was one. `not_sent` says the provider was not
    called at all (its circuit breaker is open), so nothing can have left.
    """

    def __init__(
        self,
        message: str,
        status: int | None = None,
        *,
        not_sent: bool = False,
    ):
        """Keep the message, the HTTP status (when there was one) and whether
        the provider was not called at all.
        """
        super().__init__(message)
        self.status = status
        self.not_sent = not_sent

    @property
    def delivery_rejected(self) -> bool:
        """Nothing was sent for sure, so the delivery quota is given back:
        the provider refused, or was not called."""
        return self.not_sent or self.status in {400, 401, 403, 404, 422, 429}


class SmsSender(ABC):
    """What every code sender does: send a code to a phone number, and check a
    code typed for it.
    """
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


class DemoSmsSender(SmsSender):
    """`sender` for every number except `demo_phones`, which `code` signs
    in."""

    def __init__(self, sender: SmsSender, demo_phones: Iterable[str],
                 code: str):
        """Wrap `sender`; the numbers in `demo_phones` sign in with `code`."""
        self._sender = sender
        self._demo_phones = frozenset(demo_phones)
        self._code = code

    def send_code(self, phone: str) -> None:
        """A demo number gets no SMS; any other number goes to the real sender.
        """
        if phone in self._demo_phones:
            return
        self._sender.send_code(phone)

    def check_code(self, phone: str, code: str) -> bool:
        """A demo number is checked against the demo code; any other number by
        the real sender.
        """
        if phone in self._demo_phones:
            return hmac.compare_digest(code.encode(), self._code.encode())
        return self._sender.check_code(phone, code)
