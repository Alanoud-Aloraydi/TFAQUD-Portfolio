import pytest

from app import create_app
from app.auth.otp_store import InMemoryOtpStore
from app.auth.store import InMemorySessionStore
from app.clock import SystemClock
from app.config import ConfigError, load_config
from app.sms import FakeSmsSender


def test_the_default_access_token_lifetime_is_the_proposal_of_tfqd_11(app):
    assert app.config["ACCESS_TOKEN_MINUTES"] == 15
    # A refresh token has no lifetime to set: it ends only at sign-out.
    assert "REFRESH_TOKEN_DAYS" not in app.config


def test_the_access_token_lifetime_can_be_changed_by_environment_variable(
    monkeypatch,
):
    monkeypatch.setenv("ACCESS_TOKEN_MINUTES", "5")

    config = load_config("testing")

    assert config["ACCESS_TOKEN_MINUTES"] == 5


@pytest.mark.parametrize("value", ["abc", "0", "-3", "1.5"])
def test_bad_token_lifetime_is_refused(monkeypatch, value):
    monkeypatch.setenv("ACCESS_TOKEN_MINUTES", value)

    with pytest.raises(ConfigError, match="ACCESS_TOKEN_MINUTES"):
        load_config("testing")


def test_unknown_environment_is_refused():
    with pytest.raises(ConfigError, match="APP_ENV"):
        load_config("prod")


def test_app_environment_comes_from_app_env_by_default(monkeypatch):
    monkeypatch.setenv("APP_ENV", "testing")

    assert load_config()["APP_ENV"] == "testing"


@pytest.mark.parametrize("env", ["staging", "production"])
def test_staging_and_production_need_a_real_secret_key(monkeypatch, env):
    monkeypatch.delenv("SECRET_KEY", raising=False)

    with pytest.raises(ConfigError, match="SECRET_KEY"):
        load_config(env)


def test_a_short_secret_key_is_refused(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "too-short")

    with pytest.raises(ConfigError, match="SECRET_KEY"):
        load_config("staging")


def test_development_works_without_any_setup(monkeypatch):
    monkeypatch.delenv("SECRET_KEY", raising=False)

    app = create_app("development")

    # The developer reads the code in the log.
    assert app.config["FAKE_SMS_LOG_BODY"] is True


def test_production_refuses_the_in_memory_session_store(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "x" * 40)
    # A sender object is passed in so that the SMS rule does not stop the app
    # first: this test is about the session store rule alone.
    sender = FakeSmsSender(SystemClock())

    with pytest.raises(ConfigError, match="in-memory session store"):
        create_app("production", sms_sender=sender)


def test_staging_starts_with_a_warning_about_the_in_memory_store(
    monkeypatch, caplog
):
    monkeypatch.setenv("SECRET_KEY", "x" * 40)

    with caplog.at_level("WARNING"):
        create_app("staging")

    assert "in-memory session store" in caplog.text


def test_a_given_session_store_is_used_without_warning(monkeypatch, caplog):
    monkeypatch.setenv("SECRET_KEY", "x" * 40)
    store = InMemorySessionStore()

    with caplog.at_level("WARNING"):
        app = create_app("staging", session_store=store)

    assert app.extensions["session_service"]._store is store
    assert "in-memory session store" not in caplog.text


def test_default_code_validity_is_300_seconds_like_the_authentica_dashboard(
    app,
):
    assert app.config["OTP_VALID_SECONDS"] == 300


def test_code_validity_can_be_changed_by_environment_variable(monkeypatch):
    monkeypatch.setenv("OTP_VALID_SECONDS", "120")

    assert load_config("testing")["OTP_VALID_SECONDS"] == 120


@pytest.mark.parametrize(
    "name", ["OTP_VALID_SECONDS", "AUTHENTICA_TEMPLATE_ID"]
)
@pytest.mark.parametrize("value", ["abc", "0", "-3", "1.5"])
def test_bad_otp_numbers_are_refused(monkeypatch, name, value):
    monkeypatch.setenv(name, value)

    with pytest.raises(ConfigError, match=name):
        load_config("testing")


def test_default_authentica_template_is_5(app):
    assert app.config["AUTHENTICA_TEMPLATE_ID"] == 5


def test_authentica_template_can_be_changed_by_environment_variable(
    monkeypatch,
):
    monkeypatch.setenv("AUTHENTICA_TEMPLATE_ID", "31")

    assert load_config("testing")["AUTHENTICA_TEMPLATE_ID"] == 31


def test_the_authentica_key_is_read_from_the_environment_outside_tests(
    monkeypatch,
):
    monkeypatch.setenv("AUTHENTICA_API_KEY", "k" * 30)

    assert load_config("development")["AUTHENTICA_API_KEY"] == "k" * 30


def test_the_testing_environment_never_reads_the_authentica_key(monkeypatch):
    monkeypatch.setenv("AUTHENTICA_API_KEY", "k" * 30)

    assert load_config("testing")["AUTHENTICA_API_KEY"] is None


def test_default_sign_in_limits_are_the_ones_of_tfqd_13(app):
    assert app.config["OTP_MAX_WRONG_TRIES"] == 3
    assert app.config["OTP_MAX_SENDS_PER_DAY"] == 20


def test_sign_in_limits_can_be_changed_by_environment_variable(monkeypatch):
    monkeypatch.setenv("OTP_MAX_WRONG_TRIES", "5")
    monkeypatch.setenv("OTP_MAX_SENDS_PER_DAY", "10")

    config = load_config("testing")

    limits = (config["OTP_MAX_WRONG_TRIES"], config["OTP_MAX_SENDS_PER_DAY"])
    assert limits == (5, 10)


@pytest.mark.parametrize(
    "name", ["OTP_MAX_WRONG_TRIES", "OTP_MAX_SENDS_PER_DAY"]
)
@pytest.mark.parametrize("value", ["abc", "0", "-3", "1.5"])
def test_bad_sign_in_limits_are_refused(monkeypatch, name, value):
    monkeypatch.setenv(name, value)

    with pytest.raises(ConfigError, match=name):
        load_config("testing")


def test_production_refuses_the_in_memory_code_and_user_stores(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "x" * 40)
    sender = FakeSmsSender(SystemClock())
    sessions = InMemorySessionStore()

    with pytest.raises(ConfigError, match="in-memory sign-in code store"):
        create_app("production", sms_sender=sender, session_store=sessions)

    with pytest.raises(ConfigError, match="in-memory user store"):
        create_app(
            "production",
            sms_sender=sender,
            session_store=sessions,
            otp_store=InMemoryOtpStore(),
        )


def test_staging_warns_about_every_in_memory_store(monkeypatch, caplog):
    monkeypatch.setenv("SECRET_KEY", "x" * 40)

    with caplog.at_level("WARNING"):
        create_app("staging")

    assert "in-memory sign-in code store" in caplog.text
    assert "in-memory user store" in caplog.text


def test_staging_logs_the_fake_codes_only_when_asked(monkeypatch):
    # Render runs the team's test server in staging: the fake sender writes
    # its codes in the log only with FAKE_SMS_LOG_CODES=true.
    monkeypatch.setenv("SECRET_KEY", "x" * 40)
    monkeypatch.delenv("FAKE_SMS_LOG_CODES", raising=False)
    assert load_config("staging")["FAKE_SMS_LOG_BODY"] is False

    monkeypatch.setenv("FAKE_SMS_LOG_CODES", "true")
    assert load_config("staging")["FAKE_SMS_LOG_BODY"] is True
    assert load_config("production")["FAKE_SMS_LOG_BODY"] is False


def test_the_real_servers_wait_between_codes_and_cap_the_askers(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "x" * 40)
    for name in ("OTP_RESEND_WAITS", "OTP_MAX_SENDS_PER_DEVICE_HOUR",
                 "OTP_MAX_SENDS_PER_IP_HOUR"):
        monkeypatch.delenv(name, raising=False)

    config = load_config("staging")

    assert config["OTP_RESEND_WAITS"] == (30, 60, 120, 300, 600)
    assert config["OTP_MAX_SENDS_PER_DEVICE_HOUR"] == 10
    assert config["OTP_MAX_SENDS_PER_IP_HOUR"] == 30
    # The tests send many codes in a row, so there are none there.
    testing = load_config("testing")
    assert testing["OTP_RESEND_WAITS"] == ()
    assert testing["OTP_MAX_SENDS_PER_DEVICE_HOUR"] is None


@pytest.mark.parametrize("value", ["abc", "30,x", "30,-1"])
def test_bad_waits_are_refused(monkeypatch, value):
    monkeypatch.setenv("OTP_RESEND_WAITS", value)

    with pytest.raises(ConfigError, match="OTP_RESEND_WAITS"):
        load_config("testing")


def test_zero_turns_a_wait_or_a_cap_off(monkeypatch):
    monkeypatch.setenv("OTP_RESEND_WAITS", "0")
    monkeypatch.setenv("OTP_MAX_SENDS_PER_IP_HOUR", "0")

    config = load_config("testing")

    assert config["OTP_RESEND_WAITS"] == ()
    assert config["OTP_MAX_SENDS_PER_IP_HOUR"] is None
