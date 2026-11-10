"""Allow one or more companions on an appointment.

Revision ID: 0018
Revises: 0017
"""

from alembic import op
import sqlalchemy as sa

revision = "0018"
down_revision = "0017"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Move existing companions into a constrained association table."""
    op.create_table(
        "appointment_companion",
        sa.Column("appointment_id", sa.Uuid(), nullable=False),
        sa.Column("account_id", sa.Uuid(), nullable=False),
        sa.ForeignKeyConstraint(
            ["appointment_id"], ["appointment.id"],
            ondelete="CASCADE",
            name=op.f("fk_appointment_companion_appointment_id_appointment"),
        ),
        sa.ForeignKeyConstraint(
            ["account_id"], ["account.id"],
            ondelete="RESTRICT",
            name=op.f("fk_appointment_companion_account_id_account"),
        ),
        sa.PrimaryKeyConstraint(
            "appointment_id", "account_id",
            name=op.f("pk_appointment_companion"),
        ),
    )
    op.create_index(
        "ix_appointment_companion_account_id",
        "appointment_companion", ["account_id"],
    )
    op.execute(
        "INSERT INTO appointment_companion (appointment_id, account_id) "
        "SELECT id, companion_account_id FROM appointment"
    )
    op.drop_constraint(
        "fk_appointment_companion_account_id_account",
        "appointment", type_="foreignkey",
    )
    op.drop_column("appointment", "companion_account_id")
    op.execute("""
        CREATE FUNCTION require_appointment_companion()
        RETURNS trigger LANGUAGE plpgsql AS $$
        DECLARE appointment_key uuid;
        BEGIN
            IF TG_TABLE_NAME = 'appointment' THEN
                appointment_key := NEW.id;
            ELSIF TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN
                appointment_key := OLD.appointment_id;
            ELSE
                appointment_key := NEW.appointment_id;
            END IF;
            IF EXISTS (
                SELECT 1 FROM appointment WHERE id = appointment_key
            ) AND NOT EXISTS (
                SELECT 1 FROM appointment_companion
                WHERE appointment_id = appointment_key
            ) THEN
                RAISE EXCEPTION 'An appointment needs a companion'
                    USING ERRCODE = '23514',
                    CONSTRAINT = 'ck_appointment_has_companion';
            END IF;
            RETURN NULL;
        END;
        $$
    """)
    op.execute("""
        CREATE CONSTRAINT TRIGGER ck_appointment_has_companion_insert
        AFTER INSERT OR UPDATE ON appointment
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW EXECUTE FUNCTION require_appointment_companion()
    """)
    op.execute("""
        CREATE CONSTRAINT TRIGGER ck_appointment_has_companion_remove
        AFTER DELETE OR UPDATE ON appointment_companion
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW EXECUTE FUNCTION require_appointment_companion()
    """)


def downgrade() -> None:
    """Retain one companion per appointment on the older schema."""
    op.execute(
        "DROP TRIGGER ck_appointment_has_companion_remove "
        "ON appointment_companion"
    )
    op.execute(
        "DROP TRIGGER ck_appointment_has_companion_insert "
        "ON appointment"
    )
    op.execute("DROP FUNCTION require_appointment_companion()")
    op.add_column(
        "appointment", sa.Column("companion_account_id", sa.Uuid())
    )
    op.execute("""
        UPDATE appointment AS a SET companion_account_id = chosen.account_id
        FROM (
            SELECT DISTINCT ON (appointment_id)
                appointment_id, account_id
            FROM appointment_companion
            ORDER BY appointment_id, account_id
        ) AS chosen
        WHERE a.id = chosen.appointment_id
    """)
    op.alter_column("appointment", "companion_account_id", nullable=False)
    op.create_foreign_key(
        "fk_appointment_companion_account_id_account",
        "appointment", "account", ["companion_account_id"], ["id"],
        ondelete="RESTRICT",
    )
    op.drop_index(
        "ix_appointment_companion_account_id",
        table_name="appointment_companion",
    )
    op.drop_table("appointment_companion")
