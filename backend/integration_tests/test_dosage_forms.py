"""Every dosage form the app offers saves on PostgreSQL with each of its
dose units: the version's own list and the plan check both allow it."""

from datetime import datetime, timezone

import pytest

from integration_tests.helpers import offline_circle
from integration_tests.test_medications import (
    create_plan,
    plan_body,
    signed_in,
)

# The dose units of each form, as the app pairs them (DosageFormUnit).
FORM_UNITS = [
    ("tablet", "tablet"),
    ("capsule", "capsule"),
    ("liquid", "mL"),
    ("drops", "drop"),
    ("inhaler", "puff"),
    ("nebulizer", "mL"),
    ("injection", "mL"),
    ("injection", "unit"),
]


@pytest.mark.parametrize(("form", "unit"), FORM_UNITS)
def test_each_form_saves_with_its_units(
    database_app, database, account, form, unit
):
    owner = account()
    circle = offline_circle(database, owner)
    body = plan_body(datetime.now(timezone.utc), dosage_form=form)
    body["schedules"][0]["dose_unit"] = unit

    created = create_plan(
        database_app.test_client(),
        circle,
        signed_in(database_app, owner),
        body,
    )

    assert created.status_code == 201, created.json
    assert created.json["medication_plan"]["version"]["dosage_form"] == form


def test_a_form_with_another_forms_unit_is_still_refused(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    body = plan_body(datetime.now(timezone.utc), dosage_form="nebulizer")
    body["schedules"][0]["dose_unit"] = "puff"

    refused = create_plan(
        database_app.test_client(),
        circle,
        signed_in(database_app, owner),
        body,
    )

    assert refused.status_code == 422, refused.json
