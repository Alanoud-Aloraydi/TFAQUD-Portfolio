"""The demo accounts' sign-in on a server that sends real SMS.

The demo numbers are made up (app/demo_accounts.py), so a code sent to one
could reach a stranger. With DEMO_SIGN_IN_CODE set, those numbers get no SMS
and sign in with that one code; every other number goes to the real sender
as before. The sign-in service still counts the codes and the wrong tries
of a demo number, as for any other.
"""

import hmac
from collections.abc import Iterable

from app.sms.base import SmsSender


class DemoSmsSender(SmsSender):
    """`sender` for every number except `demo_phones`, which `code` signs
    in."""

    def __init__(self, sender: SmsSender, demo_phones: Iterable[str],
                 code: str):
        self._sender = sender
        self._demo_phones = frozenset(demo_phones)
        self._code = code

    def send_code(self, phone: str) -> None:
        if phone in self._demo_phones:
            return
        self._sender.send_code(phone)

    def check_code(self, phone: str, code: str) -> bool:
        if phone in self._demo_phones:
            return hmac.compare_digest(code.encode(), self._code.encode())
        return self._sender.check_code(phone, code)
