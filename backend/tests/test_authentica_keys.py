"""Authentica with backup keys: codes go out with the next key when an
account is low on points, and a code is checked with the key that sent it.
No test opens a network connection."""

import http.client
import logging

import pytest

from app import create_app
from app.clock import ManualClock
from app.sms import AuthenticaSmsSender
from app.sms.authentica_keys import read_balance
from app.sms.authentica_keys import AuthenticaKeys
from app.sms.base import SmsDeliveryError

PHONE = "+966500000001"


class Account:
    """One Authentica account: its points, and the codes it sent."""

    def __init__(self, points=100.0, refuse=None):
        self.points = points
        self.refuse = refuse
        self.sent = []
        self.balance_reads = 0

    def balance(self):
        self.balance_reads += 1
        return self.points

    def send_code(self, phone):
        if self.refuse is not None:
            raise SmsDeliveryError("refused", status=self.refuse)
        self.sent.append(phone)

    def check_code(self, phone, code):
        return phone in self.sent and code == "123456"


def keys(*accounts, low=20, clock=None):
    return AuthenticaKeys(accounts, low=low, clock=clock or ManualClock())


def test_the_first_key_sends_while_it_has_points():
    first, backup = Account(77), Account(500)

    keys(first, backup).send_code(PHONE)

    assert first.sent == [PHONE]
    assert backup.sent == []


def test_a_key_low_on_points_hands_over_to_the_backup(caplog):
    first, backup = Account(12), Account(500)
    sender = keys(first, backup)

    with caplog.at_level(logging.WARNING):
        sender.send_code(PHONE)

    assert backup.sent == [PHONE]
    assert first.sent == []
    assert "key 1 has 12 points, under 20" in caplog.text
    # The code is checked with the key that sent it.
    assert sender.check_code(PHONE, "123456") is True


def test_a_refusal_tries_the_next_key_but_a_server_error_does_not():
    out_of_points, backup = Account(refuse=402), Account()
    keys(out_of_points, backup).send_code(PHONE)
    assert backup.sent == [PHONE]

    down, other = Account(refuse=503), Account()
    with pytest.raises(SmsDeliveryError):
        keys(down, other).send_code(PHONE)
    assert other.sent == []


def test_when_every_key_is_low_the_one_with_most_points_sends():
    a, b, c = Account(5), Account(15), Account(9)

    keys(a, b, c).send_code(PHONE)

    assert b.sent == [PHONE]


def test_a_key_that_cannot_say_its_balance_counts_as_ready():
    first, backup = Account(None), Account(500)

    keys(first, backup).send_code(PHONE)

    assert first.sent == [PHONE]


def test_the_balance_is_read_at_most_every_five_minutes():
    clock = ManualClock()
    first = Account(77)
    sender = keys(first, Account(), clock=clock)

    sender.send_code(PHONE)
    sender.send_code(PHONE)
    clock.advance(minutes=6)
    sender.send_code(PHONE)

    assert first.balance_reads == 2


def test_a_code_sent_by_another_worker_is_still_found():
    first, backup = Account(), Account()
    backup.sent.append(PHONE)

    assert keys(first, backup).check_code(PHONE, "123456") is True
    assert keys(first, backup).check_code(PHONE, "000000") is False


def test_a_check_no_key_could_answer_is_not_a_wrong_code():
    class Down(Account):
        def check_code(self, phone, code):
            raise SmsDeliveryError("down", status=503)

    with pytest.raises(SmsDeliveryError):
        keys(Down(), Down()).check_code(PHONE, "123456")


@pytest.mark.parametrize(
    ("answer", "points"),
    [
        ((200, {"data": {"balance": 77}}), 77.0),
        ((200, {"data": {"balance": "12.5"}}), 12.5),
        ((200, {"data": {}}), None),
        ((200, {"balance": 77}), None),
        ((401, {"message": "Unauthorized"}), None),
        ((200, None), None),
    ],
)
def test_the_balance_is_read_from_its_answer(answer, points):
    calls = []

    def get(url, headers, timeout):
        calls.append((url, headers))
        return answer

    assert read_balance(get, "https://a.test/api/v2", "k", 5) == points
    assert calls == [
        ("https://a.test/api/v2/balance", {"X-Authorization": "k"})
    ]


def test_no_answer_about_the_balance_is_none():
    def get(url, headers, timeout):
        raise http.client.RemoteDisconnected("closed")

    assert read_balance(get, "https://a.test/api/v2", "k", 5) is None


def test_backup_keys_build_the_switching_sender_without_any_call():
    app = create_app(
        "development",
        overrides={
            "SMS_BACKEND": "authentica",
            "AUTHENTICA_API_KEY": "k" * 30,
            "AUTHENTICA_BACKUP_API_KEYS": ("b" * 30,),
        },
    )
    single = create_app(
        "development",
        overrides={
            "SMS_BACKEND": "authentica", "AUTHENTICA_API_KEY": "k" * 30,
        },
    )

    assert isinstance(app.extensions["sms_sender"], AuthenticaKeys)
    assert isinstance(single.extensions["sms_sender"], AuthenticaSmsSender)
