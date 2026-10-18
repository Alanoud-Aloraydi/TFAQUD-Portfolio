"""The by-hand check scripts/try_authentica_sender.py, run here with the fake sender."""

import importlib.util
from pathlib import Path

import pytest

from app.sms import FakeSmsSender, SmsDeliveryError
from app.clock import ManualClock

SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "try_authentica_sender.py"
PHONE = "+966500000001"


@pytest.fixture(scope="module")
def script():
    spec = importlib.util.spec_from_file_location("try_authentica_sender", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def typing(sender, answers):
    """An `ask` function that types the answers, and the real code at its prompt."""
    answers = iter(answers)

    def ask(prompt):
        if "6-digit code" in prompt:
            return sender.last_message_to(PHONE).code
        return next(answers)

    return ask


def test_every_result_is_as_expected_with_a_sender_that_follows_the_rules(script):
    sender = FakeSmsSender(ManualClock())
    said = []

    ok = script.run(sender, ask=typing(sender, [PHONE, "yes"]), say=said.append)

    assert ok is True
    assert len(sender.outbox) == 1
    assert sum(line.startswith("OK") for line in said) == 3


def test_it_sends_nothing_unless_the_answer_is_yes(script):
    sender = FakeSmsSender(ManualClock())
    said = []

    ok = script.run(sender, ask=typing(sender, [PHONE, "no"]), say=said.append)

    assert ok is False
    assert sender.outbox == []
    assert "Nothing was sent" in said[-1]


def test_a_sender_that_accepts_a_used_code_is_reported_as_a_failure(script):
    class Careless(FakeSmsSender):
        def check_code(self, phone, code):
            return True

    sender = Careless(ManualClock())
    said = []

    ok = script.run(sender, ask=typing(sender, [PHONE, "yes"]), say=said.append)

    assert ok is False
    assert any(line.startswith("FAIL") for line in said)


def test_a_sender_error_is_printed_and_reported(script):
    class Broken(FakeSmsSender):
        def send_code(self, phone):
            raise SmsDeliveryError("Authentica answered send-otp with HTTP 401.", status=401)

    sender = Broken(ManualClock())
    said = []

    ok = script.run(sender, ask=typing(sender, [PHONE, "yes"]), say=said.append)

    assert ok is False
    assert "HTTP 401" in said[-1]


def test_without_a_key_it_stops_before_asking_anything(script, monkeypatch, capsys):
    monkeypatch.delenv("AUTHENTICA_API_KEY", raising=False)

    assert script.main() == 2
    assert "AUTHENTICA_API_KEY is not set" in capsys.readouterr().out
