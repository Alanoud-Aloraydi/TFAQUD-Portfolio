"""Database configuration validation without connecting to a server."""

import pytest

from app.config import ConfigError, load_config


def test_testing_does_not_inherit_database_credentials(monkeypatch):
    """A developer's connection is never the implicit unit-test target."""
    monkeypatch.setenv("DATABASE_URL", "postgresql://example/private")
    assert load_config("testing")["SQLALCHEMY_DATABASE_URI"] is None


def test_plain_postgres_urls_select_psycopg3():
    """The default PostgreSQL dialect otherwise selects psycopg2."""
    config = load_config(
        "testing",
        {
            "SQLALCHEMY_DATABASE_URI": "postgresql://localhost/example",
        },
    )
    assert config["SQLALCHEMY_DATABASE_URI"].drivername == "postgresql+psycopg"


@pytest.mark.parametrize("url", ["sqlite://", "mysql://localhost/example"])
def test_other_database_backends_are_rejected(url):
    """SQLite cannot stand in for deferred PostgreSQL constraints."""
    with pytest.raises(ConfigError, match="requires PostgreSQL"):
        load_config("testing", {"SQLALCHEMY_DATABASE_URI": url})


def test_invalid_url_does_not_echo_secrets():
    """Configuration errors must not print an invalid credential value."""
    with pytest.raises(ConfigError) as captured:
        load_config(
            "testing",
            {
                "SQLALCHEMY_DATABASE_URI": "private-credential-value",
            },
        )
    assert "private-credential-value" not in str(captured.value)


def test_every_connection_has_deadlines():
    """A hung query, a held lock or a busy pool ends; none waits forever."""
    options = load_config("testing")["SQLALCHEMY_ENGINE_OPTIONS"]

    assert options["pool_timeout"] == 5
    assert options["connect_args"]["connect_timeout"] == 5
    assert options["connect_args"]["options"] == (
        "-c statement_timeout=5000 -c lock_timeout=3000 "
        "-c idle_in_transaction_session_timeout=30000"
    )


def test_the_deadlines_can_be_changed(monkeypatch):
    monkeypatch.setenv("DATABASE_STATEMENT_TIMEOUT_MS", "8000")
    monkeypatch.setenv("DATABASE_LOCK_TIMEOUT_MS", "1000")
    monkeypatch.setenv("DATABASE_POOL_TIMEOUT_SECONDS", "2")

    options = load_config("testing")["SQLALCHEMY_ENGINE_OPTIONS"]

    assert "statement_timeout=8000" in options["connect_args"]["options"]
    assert "lock_timeout=1000" in options["connect_args"]["options"]
    assert options["pool_timeout"] == 2


@pytest.mark.parametrize("value", ["0", "-5", "soon"])
def test_a_deadline_must_be_a_number_above_zero(monkeypatch, value):
    """Zero would mean "no deadline", the thing this setting prevents."""
    monkeypatch.setenv("DATABASE_STATEMENT_TIMEOUT_MS", value)

    with pytest.raises(ConfigError):
        load_config("testing")
