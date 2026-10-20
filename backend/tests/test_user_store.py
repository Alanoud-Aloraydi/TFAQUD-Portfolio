"""The rules every UserStore must follow (same idea as test_otp_store.py)."""

import threading
from datetime import datetime, timezone

import pytest

from app.users.store import InMemoryUserStore

STORES = [InMemoryUserStore]

PHONE = "+966501234567"
OTHER_PHONE = "+966512345678"
NOW = datetime(2026, 10, 15, 12, 0, 0, tzinfo=timezone.utc)


@pytest.fixture(params=STORES)
def store(request):
    return request.param()


def test_a_new_phone_number_creates_a_user_without_a_profile(store):
    user, created = store.get_or_create_by_phone(PHONE, NOW)

    assert created is True
    assert user.phone == PHONE
    assert user.created_at == NOW
    assert (user.first_name, user.last_name, user.display_name) == (None, None, None)
    assert user.profile_complete is False


def test_the_same_phone_number_gives_the_same_user(store):
    first, created_first = store.get_or_create_by_phone(PHONE, NOW)
    second, created_second = store.get_or_create_by_phone(PHONE, NOW)

    assert second.id == first.id
    assert (created_first, created_second) == (True, False)


def test_different_phone_numbers_give_different_users(store):
    first, _ = store.get_or_create_by_phone(PHONE, NOW)
    second, _ = store.get_or_create_by_phone(OTHER_PHONE, NOW)

    assert first.id != second.id


def test_get_finds_a_user_by_id(store):
    user, _ = store.get_or_create_by_phone(PHONE, NOW)

    assert store.get(user.id) == user
    assert store.get("does-not-exist") is None


def test_update_profile_replaces_the_three_names(store):
    user, _ = store.get_or_create_by_phone(PHONE, NOW)

    updated = store.update_profile(user.id, "Leen", "Algraawi", "Leen")

    assert (updated.first_name, updated.last_name, updated.display_name) == (
        "Leen",
        "Algraawi",
        "Leen",
    )
    assert updated.profile_complete is True
    assert store.get(user.id) == updated


def test_update_profile_of_an_unknown_user_is_none(store):
    assert store.update_profile("does-not-exist", "A", "B", "C") is None


def test_the_public_form_of_a_user_has_no_secret_fields(store):
    user, _ = store.get_or_create_by_phone(PHONE, NOW)

    assert set(user.to_dict()) == {
        "id",
        "phone",
        "first_name",
        "last_name",
        "display_name",
        "profile_complete",
    }


def test_twenty_sign_ins_at_once_create_one_user(store):
    results = []
    lock = threading.Lock()
    barrier = threading.Barrier(20)

    def target():
        barrier.wait()
        outcome = store.get_or_create_by_phone(PHONE, NOW)
        with lock:
            results.append(outcome)

    threads = [threading.Thread(target=target) for _ in range(20)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()

    assert len({user.id for user, _ in results}) == 1
    assert [created for _, created in results].count(True) == 1
