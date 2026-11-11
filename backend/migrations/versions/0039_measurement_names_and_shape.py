"""Measurements say what they are, in the words the medicines use.

- `measurement_record` is `measurement_reading`: the API and the app call
  it a reading. Its two numbers are named: `glucose_value`, or
  `systolic_value` and `diastolic_value`. Its words for «أخرى» are
  `other_text`, as in the medical file.
- A plan version has a `version_number`, a `measurement_plan_id` and
  `missed_after_minutes`, like a medicine version; its weekdays are rows
  (`measurement_plan_weekday`) instead of a bit mask, like a medicine's.
- The copies kept for an app older than reading times and conditions go:
  the version's `time_of_day` and `glucose_context`, the time's
  `glucose_context`, the reading's `glucose_context` and `condition`. The
  server derives them when an older app asks.
- A reading of a task names one of its version's reading times: a foreign
  key on (plan_version_id, scheduled_time) says so.

Revision ID: 0039
Revises: 0038
"""
from alembic import op
import sqlalchemy as sa

revision = "0039"
down_revision = "0038"
branch_labels = None
depends_on = None

_VERSION = "measurement_plan_version"
_TIME = "measurement_plan_time"
_WEEKDAY = "measurement_plan_weekday"
_OLD = "measurement_record"
_NEW = "measurement_reading"
_CONTEXTS = "('fasting', 'before_meal', 'after_meal', 'bedtime', 'other')"

_TARGET_SHAPE_OLD = (
    "(glucose_low IS NOT NULL AND glucose_high IS NOT NULL "
    "AND glucose_low BETWEEN 1 AND 999 AND glucose_high BETWEEN 1 AND 999 "
    "AND glucose_high > glucose_low AND systolic_limit IS NULL "
    "AND diastolic_limit IS NULL) OR (glucose_low IS NULL "
    "AND glucose_high IS NULL AND glucose_context IS NULL "
    "AND systolic_limit BETWEEN 1 AND 999 "
    "AND diastolic_limit BETWEEN 1 AND 999 "
    "AND systolic_limit > diastolic_limit)"
)
_TARGET_SHAPE_NEW = _TARGET_SHAPE_OLD.replace(
    "AND glucose_context IS NULL ", ""
)
_VALUE_SHAPE_OLD = (
    "(outcome = 'skipped' AND measured_at IS NULL AND value_one IS NULL "
    "AND value_two IS NULL AND followed_up_at IS NULL) OR "
    "(outcome = 'read' AND measured_at IS NOT NULL "
    "AND value_one BETWEEN 1 AND 999 AND "
    "((kind = 'glucose' AND value_two IS NULL) OR "
    "(kind = 'bp' AND value_two BETWEEN 1 AND 999 "
    "AND value_one > value_two)))"
)
_VALUE_SHAPE_NEW = (
    "(outcome = 'skipped' AND measured_at IS NULL AND glucose_value IS NULL "
    "AND systolic_value IS NULL AND diastolic_value IS NULL "
    "AND followed_up_at IS NULL) OR "
    "(outcome = 'read' AND measured_at IS NOT NULL AND "
    "((kind = 'glucose' AND glucose_value BETWEEN 1 AND 999 "
    "AND systolic_value IS NULL AND diastolic_value IS NULL) OR "
    "(kind = 'bp' AND glucose_value IS NULL "
    "AND systolic_value BETWEEN 1 AND 999 "
    "AND diastolic_value BETWEEN 1 AND 999 "
    "AND systolic_value > diastolic_value)))"
)
# The reading's constraints that keep their rule and only change table
# name: (old name, new name).
_READING_RENAMES = (
    ("pk_measurement_record", "pk_measurement_reading"),
    ("fk_measurement_record_care_circle_id_care_circle",
     "fk_measurement_reading_care_circle_id_care_circle"),
    ("fk_measurement_record_plan_version_id_measurement_plan_version",
     "fk_measurement_reading_plan_version_id_measurement_plan_version"),
    ("fk_measurement_record_recorded_by_account_id_account",
     "fk_measurement_reading_recorded_by_account_id_account"),
    ("uq_measurement_record_plan_version_id",
     "uq_measurement_reading_plan_version_scheduled_on_scheduled_time"),
    ("ck_measurement_record_kind", "ck_measurement_reading_kind"),
    ("ck_measurement_record_outcome", "ck_measurement_reading_outcome"),
    ("ck_measurement_record_conditions", "ck_measurement_reading_conditions"),
    ("ck_measurement_record_conditions_once",
     "ck_measurement_reading_conditions_once"),
    ("ck_measurement_record_skip_linked",
     "ck_measurement_reading_skip_linked"),
    ("ck_measurement_record_note_length",
     "ck_measurement_reading_note_length"),
    ("ck_measurement_record_other_condition",
     "ck_measurement_reading_other_text"),
    ("ck_measurement_record_schedule_pair",
     "ck_measurement_reading_schedule_pair"),
    ("ck_measurement_record_free_target_shape",
     "ck_measurement_reading_free_target_shape"),
)
_VERSION_RENAMES = (
    ("fk_measurement_plan_version_plan_id_measurement_plan",
     "fk_measurement_plan_version_measurement_plan_id"),
    ("uq_measurement_plan_version_plan_id",
     "uq_measurement_plan_version_measurement_plan_id_version_number"),
    ("uq_measurement_plan_version_effective_from_on",
     "uq_measurement_plan_version_measurement_plan_effective_from_on"),
    ("ck_measurement_plan_version_number",
     "ck_measurement_plan_version_version_number"),
    ("ck_measurement_plan_version_grace_minutes",
     "ck_measurement_plan_version_missed_after_minutes"),
)


def _rename(table: str, old: str, new: str) -> None:
    op.execute(f"ALTER TABLE {table} RENAME CONSTRAINT {old} TO {new}")


def upgrade() -> None:
    # --- the version: names as a medicine version's, weekdays as rows ---
    op.alter_column(_VERSION, "plan_id", new_column_name="measurement_plan_id")
    op.alter_column(_VERSION, "number", new_column_name="version_number")
    op.alter_column(
        _VERSION, "grace_minutes", new_column_name="missed_after_minutes"
    )
    for old, new in _VERSION_RENAMES:
        _rename(_VERSION, old, new)
    op.create_table(
        _WEEKDAY,
        sa.Column("plan_version_id", sa.Uuid(), nullable=False),
        sa.Column("weekday", sa.SmallInteger(), nullable=False),
        sa.CheckConstraint(
            "weekday BETWEEN 1 AND 7",
            name=op.f("ck_measurement_plan_weekday_weekday"),
        ),
        sa.ForeignKeyConstraint(
            ["plan_version_id"], [f"{_VERSION}.id"], ondelete="CASCADE",
            name=op.f("fk_measurement_plan_weekday_plan_version_id"),
        ),
        sa.PrimaryKeyConstraint(
            "plan_version_id", "weekday",
            name=op.f("pk_measurement_plan_weekday"),
        ),
    )
    op.execute(
        f"INSERT INTO {_WEEKDAY} (plan_version_id, weekday) "
        f"SELECT v.id, d FROM {_VERSION} v, generate_series(1, 7) d "
        "WHERE (v.weekdays_mask >> (d - 1)) & 1 = 1"
    )
    op.drop_constraint(
        op.f("ck_measurement_plan_version_weekdays"), _VERSION, type_="check"
    )
    op.drop_column(_VERSION, "weekdays_mask")
    # The copies of the first reading time go.
    op.drop_constraint(
        op.f("ck_measurement_plan_version_target_shape"), _VERSION,
        type_="check",
    )
    op.drop_constraint(
        op.f("ck_measurement_plan_version_glucose_context"), _VERSION,
        type_="check",
    )
    op.drop_column(_VERSION, "glucose_context")
    op.drop_column(_VERSION, "time_of_day")
    op.create_check_constraint(
        op.f("ck_measurement_plan_version_target_shape"), _VERSION,
        _TARGET_SHAPE_NEW,
    )
    # --- the reading time: named for its version, no copy of its context ---
    op.alter_column(_TIME, "version_id", new_column_name="plan_version_id")
    _rename(
        _TIME, "fk_measurement_plan_time_version_id_measurement_plan_version",
        "fk_measurement_plan_time_plan_version_id",
    )
    op.drop_constraint(
        op.f("ck_measurement_plan_time_glucose_context"), _TIME, type_="check"
    )
    op.drop_column(_TIME, "glucose_context")
    # --- the reading ---
    op.rename_table(_OLD, _NEW)
    op.execute(
        "ALTER INDEX ix_measurement_record_care_circle_id "
        "RENAME TO ix_measurement_reading_care_circle_id"
    )
    for old, new in _READING_RENAMES:
        _rename(_NEW, old, new)
    op.alter_column(_NEW, "other_condition", new_column_name="other_text")
    for column in ("glucose_value", "systolic_value", "diastolic_value"):
        op.add_column(_NEW, sa.Column(column, sa.SmallInteger()))
    op.execute(
        f"UPDATE {_NEW} SET glucose_value = value_one "
        "WHERE kind = 'glucose'"
    )
    op.execute(
        f"UPDATE {_NEW} SET systolic_value = value_one, "
        "diastolic_value = value_two WHERE kind = 'bp'"
    )
    op.drop_constraint(
        op.f("ck_measurement_record_value_shape"), _NEW, type_="check"
    )
    op.drop_column(_NEW, "value_one")
    op.drop_column(_NEW, "value_two")
    op.create_check_constraint(
        op.f("ck_measurement_reading_value_shape"), _NEW, _VALUE_SHAPE_NEW
    )
    for check in ("glucose_context", "condition", "context_kind"):
        op.drop_constraint(
            op.f(f"ck_measurement_record_{check}"), _NEW, type_="check"
        )
    op.drop_column(_NEW, "glucose_context")
    op.drop_column(_NEW, "condition")
    # A task's reading names one of its version's reading times.
    orphans = op.get_bind().execute(sa.text(
        f"SELECT count(*) FROM {_NEW} r WHERE r.plan_version_id IS NOT NULL "
        f"AND NOT EXISTS (SELECT 1 FROM {_TIME} t "
        "WHERE t.plan_version_id = r.plan_version_id "
        "AND t.time_of_day = r.scheduled_time)"
    )).scalar_one()
    if orphans:
        raise RuntimeError(
            f"{orphans} reading(s) name a time their plan version lacks; "
            "fix them before this migration."
        )
    op.create_foreign_key(
        op.f("fk_measurement_reading_plan_version_id_measurement_plan_time"),
        _NEW, _TIME, ["plan_version_id", "scheduled_time"],
        ["plan_version_id", "time_of_day"], ondelete="CASCADE",
    )
    op.create_index(
        op.f("ix_measurement_reading_recorded_by_account_id"), _NEW,
        ["recorded_by_account_id"],
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_measurement_reading_recorded_by_account_id"), table_name=_NEW
    )
    op.drop_constraint(
        op.f("fk_measurement_reading_plan_version_id_measurement_plan_time"),
        _NEW, type_="foreignkey",
    )
    op.add_column(_NEW, sa.Column("condition", sa.Text()))
    op.add_column(_NEW, sa.Column("glucose_context", sa.Text()))
    # The single fields an older app read: the first meal state and the
    # first other condition of the list.
    op.execute(
        f"UPDATE {_NEW} SET glucose_context = (SELECT c FROM unnest("
        "conditions) c WHERE c IN ('fasting', 'before_meal', 'after_meal', "
        "'bedtime', 'other') LIMIT 1) WHERE kind = 'glucose'"
    )
    op.execute(
        f"UPDATE {_NEW} SET condition = (SELECT c FROM unnest(conditions) "
        "c WHERE c IN ('exertion', 'stress', 'illness') OR (kind = 'bp' "
        "AND c = 'after_meal') LIMIT 1)"
    )
    op.create_check_constraint(
        op.f("ck_measurement_record_glucose_context"), _NEW,
        f"glucose_context IS NULL OR glucose_context IN {_CONTEXTS}",
    )
    op.create_check_constraint(
        op.f("ck_measurement_record_condition"), _NEW,
        "condition IS NULL OR condition IN "
        "('exertion', 'after_meal', 'stress', 'illness')",
    )
    op.create_check_constraint(
        op.f("ck_measurement_record_context_kind"), _NEW,
        "kind = 'glucose' OR glucose_context IS NULL",
    )
    op.add_column(_NEW, sa.Column("value_one", sa.SmallInteger()))
    op.add_column(_NEW, sa.Column("value_two", sa.SmallInteger()))
    op.execute(
        f"UPDATE {_NEW} SET value_one = COALESCE(glucose_value, "
        "systolic_value), value_two = diastolic_value"
    )
    op.drop_constraint(
        op.f("ck_measurement_reading_value_shape"), _NEW, type_="check"
    )
    for column in ("diastolic_value", "systolic_value", "glucose_value"):
        op.drop_column(_NEW, column)
    op.create_check_constraint(
        op.f("ck_measurement_record_value_shape"), _NEW, _VALUE_SHAPE_OLD
    )
    op.alter_column(_NEW, "other_text", new_column_name="other_condition")
    for old, new in _READING_RENAMES:
        _rename(_NEW, new, old)
    op.execute(
        "ALTER INDEX ix_measurement_reading_care_circle_id "
        "RENAME TO ix_measurement_record_care_circle_id"
    )
    op.rename_table(_NEW, _OLD)
    # The reading time's context copy.
    op.add_column(_TIME, sa.Column("glucose_context", sa.Text()))
    op.execute(
        f"UPDATE {_TIME} t SET glucose_context = (SELECT c FROM unnest("
        "conditions) c WHERE c IN ('fasting', 'before_meal', 'after_meal', "
        "'bedtime', 'other') LIMIT 1)"
    )
    op.create_check_constraint(
        op.f("ck_measurement_plan_time_glucose_context"), _TIME,
        f"glucose_context IS NULL OR glucose_context IN {_CONTEXTS}",
    )
    _rename(
        _TIME, "fk_measurement_plan_time_plan_version_id",
        "fk_measurement_plan_time_version_id_measurement_plan_version",
    )
    op.alter_column(_TIME, "plan_version_id", new_column_name="version_id")
    # The version's copies of its first reading time, and its bit mask.
    op.drop_constraint(
        op.f("ck_measurement_plan_version_target_shape"), _VERSION,
        type_="check",
    )
    op.add_column(_VERSION, sa.Column("time_of_day", sa.Time()))
    op.add_column(_VERSION, sa.Column("glucose_context", sa.Text()))
    op.execute(
        f"UPDATE {_VERSION} v SET time_of_day = t.time_of_day, "
        f"glucose_context = t.glucose_context FROM (SELECT DISTINCT ON "
        f"(version_id) version_id, time_of_day, glucose_context FROM {_TIME} "
        "ORDER BY version_id, time_of_day) t WHERE t.version_id = v.id"
    )
    op.alter_column(_VERSION, "time_of_day", nullable=False)
    op.create_check_constraint(
        op.f("ck_measurement_plan_version_glucose_context"), _VERSION,
        f"glucose_context IS NULL OR glucose_context IN {_CONTEXTS}",
    )
    op.create_check_constraint(
        op.f("ck_measurement_plan_version_target_shape"), _VERSION,
        _TARGET_SHAPE_OLD,
    )
    op.add_column(_VERSION, sa.Column("weekdays_mask", sa.SmallInteger()))
    op.execute(
        f"UPDATE {_VERSION} v SET weekdays_mask = (SELECT sum(1 << "
        f"(weekday - 1)) FROM {_WEEKDAY} w WHERE w.plan_version_id = v.id)"
    )
    op.alter_column(_VERSION, "weekdays_mask", nullable=False)
    op.create_check_constraint(
        op.f("ck_measurement_plan_version_weekdays"), _VERSION,
        "weekdays_mask BETWEEN 1 AND 127",
    )
    op.drop_table(_WEEKDAY)
    for old, new in _VERSION_RENAMES:
        _rename(_VERSION, new, old)
    op.alter_column(
        _VERSION, "missed_after_minutes", new_column_name="grace_minutes"
    )
    op.alter_column(_VERSION, "version_number", new_column_name="number")
    op.alter_column(_VERSION, "measurement_plan_id", new_column_name="plan_id")
