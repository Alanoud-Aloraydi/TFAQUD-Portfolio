"""/health reports a database whose tables are missing or old."""

from pathlib import Path

import pytest
from flask_migrate import downgrade, upgrade
from sqlalchemy import text

from app.health import expected_revision
from integration_tests.helpers import error_code

DIRECTORY = str(Path(__file__).resolve().parents[1] / "migrations")
URL = "/api/v1/health"


def test_a_migrated_database_is_healthy(database_app, database):
    response = database_app.test_client().get(URL)

    assert response.status_code == 200
    assert response.json == {"status": "ok"}


def test_the_expected_revision_is_where_a_migrated_database_is(database):
    with database.connect() as connection:
        current = connection.execute(
            text("SELECT version_num FROM alembic_version")
        ).scalar()

    assert expected_revision() == current


@pytest.mark.parametrize("revision", ["base", "-1"])
def test_a_database_that_is_not_migrated_is_reported(
    database_app, database, revision
):
    """A new database (base) and one version behind (-1) both answer 503."""
    downgrade(directory=DIRECTORY, revision=revision)
    try:
        response = database_app.test_client().get(URL)
        assert error_code(response, 503) == "database_not_migrated"
        assert "db upgrade" in response.json["error"]["message"]
    finally:
        upgrade(directory=DIRECTORY)
    assert database_app.test_client().get(URL).status_code == 200
