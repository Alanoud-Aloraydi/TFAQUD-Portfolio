"""The rules every OtpStore must follow.

These tests use only the OtpStore interface. When the PostgreSQL store exists
(TFQD-7), add it to `STORES` and the same tests must pass for it.
"""

import threading
from datetime import datetime, timedelta, timezone

import pytest

from app.auth.otp_store import AttemptsExhausted, InMemoryOtpStore

STORES = [InMemoryOtpStore]

PHONE = "+966501234567"
OTHER_PHONE = "+966512345678"
NOW = datetime(2026, 10, 15, 12, 0, 0, tzinfo=timezone.utc)
HOUR = timedelta(hours=1)


@pytest.fixture(params=STORES)
def store(request):
    return request.param()


def claim(store, *, request_id=None, phone=PHONE, now=NOW, max_sends=3):
    return store.claim_send(request_id, phone, now, now - HOUR, max_sends)


# ---- claim_send ------------------------------------------------------------


def test_resend_rechecks_attempt_limit_inside_reservation(store):
    request = claim(store)
    for _ in range(3):
        assert store.claim_try(request.request_id, 3)
    with pytest.raises(AttemptsExhausted):
        store.claim_send(
            request.request_id, PHONE, NOW, NOW - HOUR, 3, max_tries=3
        )


def test_claim_without_a_request_id_creates_a_request(store):
    result = claim(store)

    assert result.granted
    request = store.get_request(result.request_id)
    assert request.phone == PHONE
    assert request.created_at == NOW
    assert request.wrong_tries == 0
    assert request.verified_at is None


def test_claim_with_a_request_id_uses_that_request(store):
    first = claim(store)
    second = claim(store, request_id=first.request_id)

    assert second.granted
    assert second.request_id == first.request_id
    assert second.send_id != first.send_id


def test_claim_with_an_unknown_request_id_is_an_error(store):
    with pytest.raises(KeyError):
        claim(store, request_id="does-not-exist")


def test_get_request_of_an_unknown_id_is_none(store):
    assert store.get_request("does-not-exist") is None


def test_claim_is_refused_after_the_maximum_and_says_when_to_come_back(store):
    first = claim(store, now=NOW)
    claim(store, now=NOW + timedelta(minutes=10))
    claim(store, now=NOW + timedelta(minutes=20))

    refused = claim(store, now=NOW + timedelta(minutes=30))

    assert not refused.granted
    assert refused.request_id is None and refused.send_id is None
    assert (
        refused.oldest_send_at == NOW
    )  # the first send leaves the window first
    assert first.granted


def test_the_limit_is_per_phone_number(store):
    for _ in range(3):
        claim(store)

    assert not claim(store).granted
    assert claim(store, phone=OTHER_PHONE).granted


def test_the_window_slides(store):
    claim(store, now=NOW)
    claim(store, now=NOW + timedelta(minutes=10))
    claim(store, now=NOW + timedelta(minutes=20))

    # Just before the first send leaves the window: still refused.
    just_before = NOW + HOUR - timedelta(seconds=1)
    assert not claim(store, now=just_before).granted
    # Exactly one hour after the first send: it is outside the window.
    assert claim(store, now=NOW + HOUR).granted


def test_a_send_exactly_on_the_window_start_is_outside_the_window(store):
    claim(store, now=NOW, max_sends=1)

    assert claim(store, now=NOW + HOUR, max_sends=1).granted


def test_sends_of_the_same_request_all_count(store):
    first = claim(store)
    claim(store, request_id=first.request_id)
    claim(store, request_id=first.request_id)

    assert not claim(store, request_id=first.request_id).granted


# ---- release_send ----------------------------------------------------------


def test_releasing_a_send_gives_the_place_back(store):
    claims = [claim(store) for _ in range(3)]
    assert not claim(store).granted

    store.release_send(claims[0].send_id)

    assert claim(store).granted


def test_releasing_the_only_send_retains_failed_delivery_history(store):
    result = claim(store)

    store.release_send(result.send_id)

    assert store.get_request(result.request_id).expires_at is None
    assert claim(store, max_sends=1).granted


def test_releasing_one_send_keeps_a_request_that_has_another(store):
    first = claim(store)
    resend = claim(store, request_id=first.request_id)

    store.release_send(resend.send_id)

    assert store.get_request(first.request_id) is not None


def test_releasing_an_unknown_send_does_nothing(store):
    store.release_send("does-not-exist")


# ---- latest_send_at --------------------------------------------------------


def test_latest_send_at_is_the_time_of_the_last_send_of_the_request(store):
    first = claim(store, now=NOW)
    later = NOW + timedelta(minutes=2)
    second = claim(store, request_id=first.request_id, now=later)
    store.mark_sent(first.send_id, NOW, NOW + timedelta(minutes=5))
    store.mark_sent(second.send_id, later, later + timedelta(minutes=5))

    assert store.latest_send_at(first.request_id) == NOW + timedelta(minutes=2)


def test_latest_send_at_ignores_the_sends_of_other_requests(store):
    first = claim(store, now=NOW)
    store.mark_sent(first.send_id, NOW, NOW + timedelta(minutes=5))
    claim(store, now=NOW + timedelta(minutes=2))  # another request, same phone

    assert store.latest_send_at(first.request_id) == NOW


def test_latest_send_at_of_an_unknown_request_is_none(store):
    assert store.latest_send_at("does-not-exist") is None


# ---- claim_try / release_try ----------------------------------------------


def test_tries_are_counted_up_to_the_maximum(store):
    request_id = claim(store).request_id

    results = [store.claim_try(request_id, 3) for _ in range(5)]

    assert results == [True, True, True, False, False]
    assert store.get_request(request_id).wrong_tries == 3


def test_claim_try_of_an_unknown_request_is_false(store):
    assert store.claim_try("does-not-exist", 3) is False


def test_release_try_gives_a_try_back(store):
    request_id = claim(store).request_id
    for _ in range(3):
        store.claim_try(request_id, 3)

    store.release_try(request_id)

    assert store.get_request(request_id).wrong_tries == 2
    assert store.claim_try(request_id, 3) is True


def test_release_try_never_goes_below_zero(store):
    request_id = claim(store).request_id

    store.release_try(request_id)

    assert store.get_request(request_id).wrong_tries == 0


def test_tries_of_one_request_do_not_touch_another(store):
    first = claim(store).request_id
    second = claim(store, phone=OTHER_PHONE).request_id

    store.claim_try(first, 3)

    assert store.get_request(second).wrong_tries == 0


# ---- mark_verified ---------------------------------------------------------


def test_a_request_is_closed_once(store):
    request_id = claim(store).request_id

    assert store.mark_verified(request_id, NOW) is True
    assert store.mark_verified(request_id, NOW + timedelta(seconds=5)) is False
    assert store.get_request(request_id).verified_at == NOW


def test_marking_an_unknown_request_verified_is_false(store):
    assert store.mark_verified("does-not-exist", NOW) is False


# ---- many requests at the same moment -------------------------------------


def run_in_threads(count, work):
    results = []
    lock = threading.Lock()
    barrier = threading.Barrier(count)

    def target():
        barrier.wait()  # all threads start together
        value = work()
        with lock:
            results.append(value)

    threads = [threading.Thread(target=target) for _ in range(count)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    return results


def test_twenty_claims_at_once_get_exactly_three_places(store):
    results = run_in_threads(20, lambda: claim(store).granted)

    assert results.count(True) == 3


def test_twenty_tries_at_once_get_exactly_three_places(store):
    request_id = claim(store).request_id

    results = run_in_threads(20, lambda: store.claim_try(request_id, 3))

    assert results.count(True) == 3
    assert store.get_request(request_id).wrong_tries == 3
