"""Sign-in with the phone number and the code (F01, TFQD-13 / TFQD-35).

The tests call the real endpoints. The SMS provider is the fake sender, and the
clock is the manual one, so "one hour later" costs nothing.
"""

import pytest

from app import create_app, metrics
from app.sms.base import SmsDeliveryError
from tests.conftest import bearer

PHONE = "+966501234567"
OTHER_PHONE = "+966512345678"


# ---- helpers ---------------------------------------------------------------


def request_code(client, phone=PHONE, verification_id=None):
    body = {"phone_number": phone}
    if verification_id is not None:
        body["verification_id"] = verification_id
    return client.post("/api/v1/auth/request-code", json=body)


def verify_code(client, verification_id, code):
    return client.post(
        "/api/v1/auth/verify-code",
        json={"verification_id": verification_id, "code": code},
    )


def start(client, phone=PHONE, verification_id=None):
    """Ask for a code and return the verification id."""
    response = request_code(client, phone, verification_id)
    assert response.status_code == 200, response.get_json()
    return response.get_json()["verification_id"]


def last_code(sms, phone=PHONE):
    return sms.last_message_to(phone).code


def wrong_code_for(real):
    return "000000" if real != "000000" else "111111"


def error_of(response, status, code):
    assert response.status_code == status, response.get_json()
    error = response.get_json()["error"]
    assert error["code"] == code
    return error


def arabic_indic(digits):
    return "".join(chr(0x0660 + int(d)) for d in digits)


@pytest.fixture
def provider_calls(sms, monkeypatch):
    """Counts the calls that reach the SMS provider."""
    calls = {"send": 0, "check": 0}
    real_send, real_check = sms.send_code, sms.check_code

    def send(phone):
        calls["send"] += 1
        return real_send(phone)

    def check(phone, code):
        calls["check"] += 1
        return real_check(phone, code)

    monkeypatch.setattr(sms, "send_code", send)
    monkeypatch.setattr(sms, "check_code", check)
    return calls


def provider_is_down(sms, monkeypatch, *, send=False, check=False, status=503):
    def down(*args, **kwargs):
        raise SmsDeliveryError(
            "provider rejected the operation", status=status
        )

    if send:
        monkeypatch.setattr(sms, "send_code", down)
    if check:
        monkeypatch.setattr(sms, "check_code", down)


# ---- request-code: the normal case ----------------------------------------


def test_request_code_sends_one_sms_and_returns_a_verification_id(client, sms):
    response = request_code(client)

    assert response.status_code == 200
    body = response.get_json()
    assert set(body) == {"verification_id", "resend_after_seconds"}
    assert isinstance(body["verification_id"], str) and body["verification_id"]
    assert len(sms.outbox) == 1
    assert sms.outbox[0].to == PHONE
    assert len(sms.outbox[0].code) == 6


def test_request_code_without_a_verification_id_starts_a_new_request_each_time(
    client,
):
    first = start(client)
    second = start(client)

    assert first != second


def test_a_resend_keeps_the_same_request_and_sends_another_sms(client, sms):
    first = start(client)

    second = start(client, verification_id=first)

    assert second == first
    assert len(sms.outbox) == 2


def test_the_answer_is_the_same_for_a_new_and_a_known_phone_number(
    client, sms
):
    # Sign one phone number in, then ask for a code for it and for a new one.
    # Nothing in the answer tells them apart (no account enumeration).
    vid = start(client)
    assert verify_code(client, vid, last_code(sms)).status_code == 200

    known = request_code(client, PHONE).get_json()
    new = request_code(client, OTHER_PHONE).get_json()

    expected = {"verification_id", "resend_after_seconds"}
    assert set(known) == set(new) == expected
    assert known["resend_after_seconds"] == new["resend_after_seconds"]


# ---- request-code: input checks -------------------------------------------


@pytest.mark.parametrize(
    "phone",
    [
        "",
        "0501234567",  # local form, no country code
        "966501234567",  # no plus
        "+966401234567",  # does not start with 5
        "+96650123456",  # one digit short
        "+9665012345678",  # one digit too many
        "+966 50 123 4567",  # spaces inside
        "+96650123456a",
        # Arabic digits are not accepted for the phone.
        "+9665" + arabic_indic("01234567"),
        "+971501234567",  # another country
    ],
)
def test_a_bad_phone_number_is_refused_and_nothing_is_sent(client, sms, phone):
    response = request_code(client, phone)

    error = error_of(response, 422, "validation_error")
    assert error["details"][0]["field"] == "phone_number"
    assert error["details"][0]["code"] == "invalid_phone"
    assert sms.outbox == []


def test_a_bad_phone_number_is_never_repeated_in_the_answer(client):
    response = request_code(client, "+966401234567")

    assert "401234567" not in response.get_data(as_text=True)


def test_a_phone_number_with_spaces_around_it_is_accepted(client, sms):
    response = request_code(client, f"  {PHONE}  ")

    assert response.status_code == 200
    assert sms.outbox[0].to == PHONE


def test_request_code_needs_a_phone_number(client):
    response = client.post("/api/v1/auth/request-code", json={})

    error = error_of(response, 422, "validation_error")
    assert error["details"][0]["field"] == "phone_number"


def test_request_code_refuses_unknown_fields(client, sms):
    response = client.post(
        "/api/v1/auth/request-code",
        json={"phone_number": PHONE, "country": "SA"},
    )

    error_of(response, 422, "validation_error")
    assert sms.outbox == []


def test_request_code_needs_a_json_body(client):
    response = client.post("/api/v1/auth/request-code", data="phone=1")

    error_of(response, 400, "invalid_json")


# ---- request-code: the limit of 3 codes per phone number per hour ---------


DAY = 24 * 3600


def test_the_21st_code_of_a_day_is_refused_and_nothing_is_sent(client, sms):
    for _ in range(20):
        start(client)

    response = request_code(client)

    error = error_of(response, 429, "too_many_codes")
    assert error["retry_after_seconds"] == DAY
    assert response.headers["Retry-After"] == str(DAY)
    assert len(sms.outbox) == 20


def test_resends_count_toward_the_same_limit(client, sms):
    vid = start(client)
    for _ in range(19):
        start(client, verification_id=vid)

    response = request_code(client, verification_id=vid)

    error_of(response, 429, "too_many_codes")
    assert len(sms.outbox) == 20


def test_the_limit_belongs_to_the_phone_number(client):
    for _ in range(20):
        start(client)

    assert request_code(client, OTHER_PHONE).status_code == 200


def test_the_window_slides_and_the_answer_says_when_to_come_back(
    client, clock
):
    for _ in range(20):
        start(client)  # 12:00, 12:01, ... 12:19
        clock.advance(minutes=1)  # 12:20 after the last

    refused = request_code(client)

    # The first code (12:00) leaves the day at 12:00 tomorrow.
    wait = DAY - 20 * 60
    error = error_of(refused, 429, "too_many_codes")
    assert error["retry_after_seconds"] == wait
    assert refused.headers["Retry-After"] == str(wait)

    clock.advance(seconds=wait - 1)
    error_of(request_code(client), 429, "too_many_codes")
    clock.advance(seconds=1)
    assert request_code(client).status_code == 200


def test_a_refused_request_is_not_counted_again(client, clock):
    for _ in range(20):
        start(client)
    for _ in range(5):
        error_of(request_code(client), 429, "too_many_codes")

    clock.advance(hours=24)

    # Only the twenty real codes mattered, so the phone number is free again.
    assert request_code(client).status_code == 200


def test_a_sign_in_starts_the_count_of_the_number_again(client, sms):
    # Someone asked nineteen codes for the number; its owner then signs in
    # with the twentieth. The owner is not punished for them later.
    for _ in range(19):
        start(client)
    vid = start(client)
    assert verify_code(client, vid, last_code(sms)).status_code == 200

    assert request_code(client).status_code == 200


# ---- request-code: waits and the caps of the asker -------------------------


@pytest.fixture
def guarded(monkeypatch, clock, circle_access, otp_store, user_store):
    """An app with the real waits and small device and IP caps."""
    monkeypatch.setenv("OTP_RESEND_WAITS", "30,60,120")
    monkeypatch.setenv("OTP_MAX_SENDS_PER_DEVICE_HOUR", "3")
    monkeypatch.setenv("OTP_MAX_SENDS_PER_IP_HOUR", "5")
    monkeypatch.setenv("CLIENT_IP_HEADER", "CF-Connecting-IP")
    app = create_app(
        "testing",
        clock=clock,
        circle_access=circle_access,
        otp_store=otp_store,
        user_store=user_store,
    )
    return app.test_client()


def outbox(client):
    """The SMS the guarded app sent."""
    return client.application.extensions["sms_sender"].outbox


def ask(client, phone=PHONE, device="device-aaaa", ip="203.0.113.7", vid=None):
    body = {"phone_number": phone}
    if vid is not None:
        body["verification_id"] = vid
    return client.post(
        "/api/v1/auth/request-code",
        json=body,
        headers={"X-Device-Id": device, "CF-Connecting-IP": ip},
    )


def test_the_answer_says_when_the_next_code_may_come(guarded):
    first = ask(guarded)

    assert first.status_code == 200
    assert first.get_json()["resend_after_seconds"] == 30


def test_the_wait_grows_with_each_code_and_then_stays(guarded, clock):
    vid = ask(guarded).get_json()["verification_id"]

    error = error_of(ask(guarded, vid=vid), 429, "resend_wait")
    assert error["retry_after_seconds"] == 30

    for wait, after in ((30, 60), (60, 120), (120, 120)):
        clock.advance(seconds=wait - 1)
        error_of(ask(guarded, vid=vid, device=f"device-{wait:04d}"), 429,
                 "resend_wait")
        clock.advance(seconds=1)
        answer = ask(guarded, vid=vid, device=f"device-{wait:04d}")
        assert answer.status_code == 200, answer.get_json()
        assert answer.get_json()["resend_after_seconds"] == after


def test_a_refused_wait_sends_nothing(guarded):
    ask(guarded)
    for _ in range(5):
        error_of(ask(guarded), 429, "resend_wait")

    assert len(outbox(guarded)) == 1


def test_one_device_cannot_ask_codes_for_many_numbers(guarded):
    for n in range(3):
        assert ask(guarded, phone=f"+96650000000{n}").status_code == 200

    refused = ask(guarded, phone="+966500000009")

    error = error_of(refused, 429, "too_many_codes")
    assert error["retry_after_seconds"] == 3600
    assert len(outbox(guarded)) == 3
    # Another phone on another network may still ask.
    assert ask(guarded, phone="+966500000009", device="device-bbbb",
               ip="198.51.100.2").status_code == 200


def test_one_network_cannot_ask_codes_for_many_numbers(guarded):
    for n in range(5):
        assert ask(guarded, phone=f"+96650000000{n}",
                   device=f"device-{n:04d}").status_code == 200

    refused = ask(guarded, phone="+966500000009", device="device-9999")

    error_of(refused, 429, "too_many_codes")
    assert len(outbox(guarded)) == 5


def test_a_strange_device_id_is_ignored(guarded):
    # Too short or with other characters: the device is unknown, and only
    # the caps of the number and the network apply.
    for n in range(4):
        assert ask(guarded, phone=f"+96650000000{n}",
                   device="x!").status_code == 200


# ---- request-code: the owner's known phone ----------------------------------


def sms_code(client, phone=PHONE):
    return client.application.extensions["sms_sender"].last_message_to(
        phone
    ).code


def sign_in_on(client, device, phone=PHONE):
    """Sign in with `phone` on `device`: it becomes a known phone."""
    answer = ask(client, phone=phone, device=device)
    assert answer.status_code == 200, answer.get_json()
    vid = answer.get_json()["verification_id"]
    done = verify_code(client, vid, sms_code(client, phone))
    assert done.status_code == 200, done.get_json()


STRANGER = {"device": "device-stranger", "ip": "198.51.100.9"}


def test_a_stranger_does_not_make_the_owners_phone_wait(guarded, clock):
    sign_in_on(guarded, "device-owner")
    clock.advance(seconds=1)
    # Someone else asks for codes for the owner's number on another phone.
    assert ask(guarded, **STRANGER).status_code == 200
    error_of(ask(guarded, **STRANGER), 429, "resend_wait")

    mine = ask(guarded, device="device-owner")

    assert mine.status_code == 200, mine.get_json()
    assert mine.get_json()["resend_after_seconds"] == 30


def test_the_owners_code_makes_a_stranger_wait(guarded, clock):
    sign_in_on(guarded, "device-owner")
    clock.advance(seconds=1)
    assert ask(guarded, device="device-owner").status_code == 200

    error_of(ask(guarded, **STRANGER), 429, "resend_wait")


def test_a_known_phone_still_waits_for_its_own_codes(guarded, clock):
    sign_in_on(guarded, "device-owner")
    clock.advance(seconds=1)
    vid = ask(guarded, device="device-owner").get_json()["verification_id"]

    error_of(ask(guarded, device="device-owner", vid=vid), 429, "resend_wait")


def test_a_new_phone_waits_like_a_stranger(guarded, clock):
    sign_in_on(guarded, "device-owner")
    clock.advance(seconds=1)
    assert ask(guarded, **STRANGER).status_code == 200

    # A phone that never signed in with this number is not known.
    error_of(ask(guarded, device="device-newphone"), 429, "resend_wait")


def test_a_phone_is_known_only_for_the_number_it_signed_in_with(
    guarded, clock
):
    sign_in_on(guarded, "device-owner")
    clock.advance(seconds=1)
    assert ask(guarded, phone=OTHER_PHONE, **STRANGER).status_code == 200

    error_of(ask(guarded, phone=OTHER_PHONE, device="device-owner"), 429,
             "resend_wait")


def test_a_stranger_cannot_use_up_the_owners_codes_of_the_day(client, clock):
    sign_in_on(client, "device-owner")
    clock.advance(seconds=1)
    for _ in range(20):
        assert ask(client, **STRANGER).status_code == 200
    error_of(ask(client, **STRANGER), 429, "too_many_codes")
    error_of(ask(client, device="device-newphone"), 429, "too_many_codes")

    assert ask(client, device="device-owner").status_code == 200


def test_a_busy_network_does_not_hold_back_the_owners_phone(guarded, clock):
    sign_in_on(guarded, "device-owner")
    clock.advance(seconds=1)
    # Four more codes from the same network: its five of the hour are used.
    for n in range(4):
        assert ask(guarded, phone=f"+96650000000{n}",
                   device=f"device-{n:04d}").status_code == 200
    error_of(ask(guarded, phone="+966500000009", device="device-9999"), 429,
             "too_many_codes")

    assert ask(guarded, device="device-owner").status_code == 200


def test_a_rejected_send_does_not_count_toward_the_limit(
    client, sms, monkeypatch
):
    with monkeypatch.context() as down:
        provider_is_down(sms, down, send=True, status=422)
        for _ in range(5):
            error_of(request_code(client), 503, "sms_unavailable")

    # The provider is back. All twenty codes of the day are still available.
    for _ in range(20):
        assert request_code(client).status_code == 200
    error_of(request_code(client), 429, "too_many_codes")


# ---- request-code: the verification id -------------------------------------


def test_a_resend_for_an_unknown_verification_id_is_refused(client, sms):
    response = request_code(client, verification_id="does-not-exist")

    error_of(response, 404, "verification_not_found")
    assert sms.outbox == []


def test_a_verification_id_of_another_phone_number_is_refused(client, sms):
    vid = start(client, phone=PHONE)

    response = request_code(client, phone=OTHER_PHONE, verification_id=vid)

    error_of(response, 404, "verification_not_found")
    assert len(sms.outbox) == 1  # only the first request sent something


def test_a_finished_verification_id_cannot_be_used_for_a_resend(client, sms):
    vid = start(client)
    assert verify_code(client, vid, last_code(sms)).status_code == 200

    response = request_code(client, verification_id=vid)

    error_of(response, 404, "verification_not_found")


def test_no_sms_is_sent_into_a_request_that_has_no_tries_left(client, sms):
    vid = start(client)
    wrong = wrong_code_for(last_code(sms))
    for _ in range(3):
        error_of(verify_code(client, vid, wrong), 422, "invalid_code")

    response = request_code(client, verification_id=vid)

    error_of(response, 429, "too_many_attempts")
    assert len(sms.outbox) == 1


# ---- request-code: the provider is down ------------------------------------


def test_a_provider_failure_gives_503(client, sms, monkeypatch):
    provider_is_down(sms, monkeypatch, send=True)

    response = request_code(client)

    error_of(response, 503, "sms_unavailable")


def test_a_rejected_first_send_retains_history_without_otp_expiration(
    client, sms, monkeypatch, otp_store
):
    provider_is_down(sms, monkeypatch, send=True, status=422)
    request_code(client)

    request = next(iter(otp_store._requests.values()))
    send = next(iter(otp_store._sends.values()))
    assert request.expires_at is None
    assert send.status == "failed"


def test_a_failed_resend_keeps_the_request_so_the_user_can_try_again(
    client, sms, monkeypatch
):
    vid = start(client)
    first_code = last_code(sms)
    with monkeypatch.context() as down:
        provider_is_down(sms, down, send=True)
        error_of(
            request_code(client, verification_id=vid), 503, "sms_unavailable"
        )

    # The first SMS is still good, and the request is still open.
    assert verify_code(client, vid, first_code).status_code == 200


# ---- verify-code: the normal case ------------------------------------------


def test_the_right_code_signs_the_user_in(client, sms):
    vid = start(client)

    response = verify_code(client, vid, last_code(sms))

    assert response.status_code == 200
    body = response.get_json()
    assert set(body) == {
        "access_token",
        "access_token_expires_at",
        "refresh_token",
        "refresh_token_expires_at",
        "account",
    }
    assert body["account"]["phone_number"] == PHONE
    assert body["account"]["first_name"] is None
    assert body["account"]["profile_complete"] is False


def test_the_access_token_from_verify_code_works(client, sms):
    vid = start(client)
    body = verify_code(client, vid, last_code(sms)).get_json()

    response = client.get(
        "/api/v1/auth/session", headers=bearer(body["access_token"])
    )

    assert response.status_code == 200
    assert response.get_json()["account_id"] == body["account"]["id"]


def test_the_refresh_token_from_verify_code_works(client, sms):
    vid = start(client)
    body = verify_code(client, vid, last_code(sms)).get_json()

    response = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": body["refresh_token"]}
    )

    assert response.status_code == 200
    assert response.get_json()["access_token"]


def test_the_same_phone_number_is_the_same_user_every_time(client, sms):
    first = verify_code(client, start(client), last_code(sms)).get_json()
    second = verify_code(client, start(client), last_code(sms)).get_json()

    assert second["account"]["id"] == first["account"]["id"]
    assert second["access_token"] != first["access_token"]
    assert second["refresh_token"] != first["refresh_token"]


def test_different_phone_numbers_are_different_users(client, sms):
    first = verify_code(
        client, start(client, PHONE), last_code(sms, PHONE)
    ).get_json()
    second = verify_code(
        client, start(client, OTHER_PHONE), last_code(sms, OTHER_PHONE)
    ).get_json()

    assert second["account"]["id"] != first["account"]["id"]


def test_the_profile_of_a_returning_user_is_returned(client, sms):
    first = verify_code(client, start(client), last_code(sms)).get_json()
    client.put(
        "/api/v1/accounts/me/profile",
        json={
            "first_name": "Leen",
            "last_name": "Algraawi",
            "display_name": "Leen",
        },
        headers=bearer(first["access_token"]),
    )

    second = verify_code(client, start(client), last_code(sms)).get_json()

    assert second["account"]["first_name"] == "Leen"
    assert second["account"]["profile_complete"] is True


def test_arabic_digits_are_accepted_for_the_code(client, sms):
    vid = start(client)

    response = verify_code(client, vid, arabic_indic(last_code(sms)))

    assert response.status_code == 200


def test_spaces_around_the_code_are_ignored(client, sms):
    vid = start(client)

    response = verify_code(client, vid, f" {last_code(sms)} ")

    assert response.status_code == 200


# ---- verify-code: wrong codes and the limit of 3 tries ---------------------


def test_a_wrong_code_is_refused_and_the_request_stays_open(
    client, sms, otp_store
):
    vid = start(client)
    real = last_code(sms)

    error_of(
        verify_code(client, vid, wrong_code_for(real)), 422, "invalid_code"
    )

    assert otp_store.get_request(vid).wrong_tries == 1
    assert verify_code(client, vid, real).status_code == 200


def test_the_right_code_still_works_on_the_third_try(client, sms):
    vid = start(client)
    real = last_code(sms)
    wrong = wrong_code_for(real)
    error_of(verify_code(client, vid, wrong), 422, "invalid_code")
    error_of(verify_code(client, vid, wrong), 422, "invalid_code")

    assert verify_code(client, vid, real).status_code == 200


def test_after_three_wrong_tries_even_the_right_code_is_refused(
    client, sms, provider_calls
):
    vid = start(client)
    real = last_code(sms)
    wrong = wrong_code_for(real)
    for _ in range(3):
        error_of(verify_code(client, vid, wrong), 422, "invalid_code")
    checks_before = provider_calls["check"]

    response = verify_code(client, vid, real)

    error_of(response, 429, "too_many_attempts")
    # The provider was not asked.
    assert provider_calls["check"] == checks_before


def test_a_resend_does_not_give_new_tries(client, sms):
    vid = start(client)
    wrong = wrong_code_for(last_code(sms))
    error_of(verify_code(client, vid, wrong), 422, "invalid_code")
    error_of(verify_code(client, vid, wrong), 422, "invalid_code")

    start(client, verification_id=vid)  # a new SMS, same request
    new_code = last_code(sms)
    error_of(
        verify_code(client, vid, wrong_code_for(new_code)),
        422,
        "invalid_code",
    )

    # Three wrong tries in total: the new, right code is now refused too.
    error_of(verify_code(client, vid, new_code), 429, "too_many_attempts")


def test_a_new_request_has_its_own_three_tries(client, sms):
    vid = start(client)
    wrong = wrong_code_for(last_code(sms))
    for _ in range(3):
        error_of(verify_code(client, vid, wrong), 422, "invalid_code")

    new_vid = start(client)

    assert new_vid != vid
    assert verify_code(client, new_vid, last_code(sms)).status_code == 200


def test_a_code_made_for_another_phone_number_is_wrong(client, sms):
    vid = start(client, PHONE)
    start(client, OTHER_PHONE)

    response = verify_code(client, vid, last_code(sms, OTHER_PHONE))

    error_of(response, 422, "invalid_code")


# ---- verify-code: expired codes --------------------------------------------


def test_a_code_works_until_300_seconds_after_it_was_sent(client, sms, clock):
    vid = start(client)
    clock.advance(seconds=300)

    assert verify_code(client, vid, last_code(sms)).status_code == 200


def test_a_wrong_code_is_expired_only_after_300_seconds(
    client, sms, clock, otp_store
):
    vid = start(client)
    wrong = wrong_code_for(last_code(sms))
    clock.advance(seconds=300)

    # Exactly 300 seconds: the code is still valid, so this is a real mistake.
    error_of(verify_code(client, vid, wrong), 422, "invalid_code")
    assert otp_store.get_request(vid).wrong_tries == 1

    clock.advance(seconds=1)

    # One second later the code has expired: not a mistake, not counted.
    error_of(verify_code(client, vid, wrong), 422, "code_expired")
    assert otp_store.get_request(vid).wrong_tries == 1


def test_an_expired_code_is_reported_as_expired_and_costs_no_try(
    client, sms, clock, otp_store
):
    vid = start(client)
    old_code = last_code(sms)
    clock.advance(seconds=301)

    error_of(verify_code(client, vid, old_code), 422, "code_expired")

    assert otp_store.get_request(vid).wrong_tries == 0


def test_expired_attempts_never_lock_the_request(client, sms, clock):
    vid = start(client)
    old_code = last_code(sms)
    clock.advance(minutes=10)
    for _ in range(5):
        error_of(verify_code(client, vid, old_code), 422, "code_expired")

    start(client, verification_id=vid)  # resend: a fresh code

    assert verify_code(client, vid, last_code(sms)).status_code == 200


def test_a_resend_restarts_the_five_minutes_of_the_request(client, sms, clock):
    vid = start(client)
    clock.advance(minutes=4)
    start(client, verification_id=vid)
    # 8 minutes after the first SMS, 4 after the second.
    clock.advance(minutes=4)

    assert verify_code(client, vid, last_code(sms)).status_code == 200


# ---- verify-code: a request is used once -----------------------------------


def test_a_finished_request_cannot_sign_in_again(client, sms, provider_calls):
    vid = start(client)
    code = last_code(sms)
    assert verify_code(client, vid, code).status_code == 200
    checks_before = provider_calls["check"]

    response = verify_code(client, vid, code)

    error_of(response, 422, "code_already_used")
    assert provider_calls["check"] == checks_before


def test_after_signing_in_a_new_request_works(client, sms):
    first = verify_code(client, start(client), last_code(sms)).get_json()

    vid = start(client)
    second = verify_code(client, vid, last_code(sms))

    assert second.status_code == 200
    assert second.get_json()["account"]["id"] == first["account"]["id"]


# ---- verify-code: input checks ---------------------------------------------


def test_a_code_for_an_unknown_verification_id_is_refused(
    client, provider_calls
):
    response = verify_code(client, "does-not-exist", "123456")

    error_of(response, 404, "verification_not_found")
    assert provider_calls["check"] == 0


@pytest.mark.parametrize(
    "code", ["", "12345", "1234567", "abcdef", "12 456", "1234.6"]
)
def test_a_badly_formed_code_is_refused_without_costing_a_try(
    client, sms, provider_calls, otp_store, code
):
    vid = start(client)

    response = verify_code(client, vid, code)

    error = error_of(response, 422, "validation_error")
    assert error["details"][0]["field"] == "code"
    assert error["details"][0]["code"] == "invalid_code_format"
    assert otp_store.get_request(vid).wrong_tries == 0
    assert provider_calls["check"] == 0


def test_a_badly_formed_code_is_never_repeated_in_the_answer(client, sms):
    vid = start(client)

    response = verify_code(client, vid, "abc123x")

    assert "abc123x" not in response.get_data(as_text=True)


def test_verify_code_needs_both_fields_and_refuses_unknown_ones(client, sms):
    vid = start(client)

    missing = client.post(
        "/api/v1/auth/verify-code", json={"verification_id": vid}
    )
    extra = client.post(
        "/api/v1/auth/verify-code",
        json={"verification_id": vid, "code": "123456", "phone_number": PHONE},
    )

    error_of(missing, 422, "validation_error")
    error_of(extra, 422, "validation_error")


# ---- verify-code: the provider is down -------------------------------------


def test_a_provider_failure_while_checking_gives_503_and_costs_no_try(
    client, sms, monkeypatch, otp_store
):
    vid = start(client)
    real = last_code(sms)
    with monkeypatch.context() as down:
        provider_is_down(sms, down, check=True)
        for _ in range(5):
            error_of(verify_code(client, vid, real), 503, "sms_unavailable")

    assert otp_store.get_request(vid).wrong_tries == 0
    assert verify_code(client, vid, real).status_code == 200


# ---- counters, and a provider that was not called --------------------------


def test_the_codes_sent_and_the_sign_ins_are_counted(client, sms):
    verification_id = start(client)

    signed_in = verify_code(client, verification_id, last_code(sms))

    assert signed_in.status_code == 200
    assert metrics.count("sign_in.code_sent") == 1
    assert metrics.count("sign_in.completed") == 1


def test_a_wrong_code_is_counted(client, sms):
    verification_id = start(client)

    verify_code(client, verification_id, wrong_code_for(last_code(sms)))

    assert metrics.count("sign_in.invalid_code") == 1


def test_a_provider_not_called_gives_the_code_back_to_the_quota(
    client, sms, monkeypatch
):
    def not_called(phone):
        raise SmsDeliveryError("breaker open", not_sent=True)

    monkeypatch.setattr(sms, "send_code", not_called)

    error_of(request_code(client), 503, "sms_unavailable")
    assert metrics.count("sign_in.code_not_sent") == 1
    # Nothing was used, so there is no wait before the next try.
    monkeypatch.undo()
    assert request_code(client).status_code == 200
