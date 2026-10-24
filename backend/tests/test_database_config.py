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
