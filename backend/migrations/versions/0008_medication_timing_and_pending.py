"""Add per-version missed timing and retain cancelled future revisions."""

from pathlib import Path

from alembic import op
import sqlalchemy as sa

revision = "0008"
down_revision = "0007"
branch_labels = None
depends_on = None


def _rule(name: str, changes: tuple[tuple[str, str], ...] = ()) -> None:
    """Reinstall one complete rule from the preceding medication migration."""
    source = Path(__file__).with_name("0007_medication_rules.sql")
    rules = source.read_text(encoding="utf-8")
    start = rules.index(f"CREATE FUNCTION {name}(")
    end = rules.index("$$;", start) + 3
    statement = rules[start:end].replace(
        "CREATE FUNCTION", "CREATE OR REPLACE FUNCTION", 1
    )
    for old, new in changes:
        if statement.count(old) != 1:
            raise RuntimeError(f"Unexpected source for medication rule {name}")
        statement = statement.replace(old, new)
    op.execute(statement)


def upgrade() -> None:
    """Backfill existing versions with the approved 60-minute default."""
    op.add_column(
        "medication_plan_version",
        sa.Column(
            "missed_after_minutes",
            sa.SmallInteger(),
            server_default=sa.text("60"),
            nullable=False,
        ),
    )
    op.add_column(
        "medication_plan_version",
        sa.Column("cancelled_at", sa.DateTime(timezone=True)),
    )
    op.create_check_constraint(
        op.f("ck_medication_plan_version_missed_after_minutes"),
        "medication_plan_version",
        "missed_after_minutes IN (30, 60, 120)",
    )
    op.drop_constraint(
        "uq_medication_plan_version_effective_from_on",
        "medication_plan_version",
        type_="unique",
    )
    op.create_index(
        "uq_medication_plan_version_effective_from_on",
        "medication_plan_version",
        ["medication_plan_id", "effective_from_on"],
        unique=True,
        postgresql_where=sa.text("cancelled_at IS NULL"),
    )
    op.drop_index(
        "uq_medication_plan_version_open",
        table_name="medication_plan_version",
    )
    op.create_index(
        "uq_medication_plan_version_open",
        "medication_plan_version",
        ["medication_plan_id"],
        unique=True,
        postgresql_where=sa.text(
            "effective_until_on IS NULL AND cancelled_at IS NULL"
        ),
    )
    _rule("medication_treatment_period", (
        (
            "IF starts_on >= ends_on THEN",
            "IF version_row.cancelled_at IS NOT NULL THEN "
            "RETURN 'empty'::daterange; END IF;\n"
            "    IF starts_on >= ends_on THEN",
        ),
    ))
    _rule("assert_medication_plan", (
        (
            "AND effective_until_on IS NULL) <> 1",
            "AND effective_until_on IS NULL\n"
            "          AND cancelled_at IS NULL) <> 1",
        ),
        (
            "WHERE medication_plan_id = plan_key\n"
            "        ) periods",
            "WHERE medication_plan_id = plan_key\n"
            "              AND cancelled_at IS NULL\n"
            "        ) periods",
        ),
    ))
    _rule("check_medication_dose", (
        (
            "AND NEW.scheduled_on >= v.effective_from_on",
            "AND v.cancelled_at IS NULL\n"
            "          AND NEW.scheduled_on >= v.effective_from_on",
        ),
    ))


def downgrade() -> None:
    """Restore the original version schema on an isolated database."""
    cancelled = op.get_bind().execute(sa.text(
        "SELECT count(*) FROM medication_plan_version "
        "WHERE cancelled_at IS NOT NULL"
    )).scalar_one()
    if cancelled:
        raise RuntimeError("Cannot downgrade cancelled medication revisions")
    for name in (
        "medication_treatment_period",
        "assert_medication_plan",
        "check_medication_dose",
    ):
        _rule(name)
    op.drop_index(
        "uq_medication_plan_version_open",
        table_name="medication_plan_version",
    )
    op.create_index(
        "uq_medication_plan_version_open",
        "medication_plan_version",
        ["medication_plan_id"],
        unique=True,
        postgresql_where=sa.text("effective_until_on IS NULL"),
    )
    op.drop_index(
        "uq_medication_plan_version_effective_from_on",
        table_name="medication_plan_version",
    )
    op.create_unique_constraint(
        "uq_medication_plan_version_effective_from_on",
        "medication_plan_version",
        ["medication_plan_id", "effective_from_on"],
    )
    op.drop_constraint(
        op.f("ck_medication_plan_version_missed_after_minutes"),
        "medication_plan_version",
        type_="check",
    )
    op.drop_column("medication_plan_version", "cancelled_at")
    op.drop_column("medication_plan_version", "missed_after_minutes")
