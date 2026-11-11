"""Migration 0037 lets the circle name be empty before it empties one."""

import importlib.util
from pathlib import Path
from unittest.mock import MagicMock

MIGRATION = (
    Path(__file__).resolve().parents[1]
    / "migrations" / "versions" / "0037_patient_is_the_care_circle.py"
)


def _upgrade_steps():
    """The operations `upgrade()` asks for, in order, without a database."""
    spec = importlib.util.spec_from_file_location("migration_0037", MIGRATION)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.op = MagicMock()
    module.upgrade()
    return module.op.method_calls


def _first_index(steps, matches):
    for index, (name, args, kwargs) in enumerate(steps):
        if matches(name, args, kwargs):
            return index
    raise AssertionError("the step is missing from upgrade()")


def test_the_name_column_allows_null_before_a_name_is_set_to_null():
    steps = _upgrade_steps()

    allows_null = _first_index(
        steps,
        lambda name, args, kwargs: name == "alter_column"
        and args[:2] == ("care_circle", "name")
        and kwargs.get("nullable") is True,
    )
    sets_null = _first_index(
        steps,
        lambda name, args, kwargs: name == "execute"
        and "SET name = NULL" in args[0],
    )

    assert allows_null < sets_null
