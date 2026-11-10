"""An appointment needs no companion: going with the patient is optional.

Before, the database refused an appointment with no companion (a trigger
on each new appointment, and one on every change of its companions). Both
triggers go, and their function. The patient is still reminded of every
appointment; a companion only adds who else is.

Going back is refused while some appointment has no companion, as 0029's
downgrade is: the old rule could not hold for it.

Revision ID: 0032
Revises: 0031
"""

from alembic import op
import sqlalchemy as sa

revision = "0032"
down_revision = "0031"
branch_labels = None
depends_on = None

# The function as 0029 left it: a companion that went with its deleted
# account does not count against the rule.
_RULE = """
    CREATE FUNCTION require_appointment_companion()
    RETURNS trigger LANGUAGE plpgsql AS $$
    DECLARE appointment_key uuid;
    BEGIN
        IF TG_TABLE_NAME = 'appointment_companion' AND TG_OP = 'DELETE'
        THEN
            IF NOT EXISTS (
                SELECT 1 FROM account WHERE id = OLD.account_id
            ) THEN
                RETURN NULL;
            END IF;
        END IF;
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
"""


def upgrade() -> None:
    op.execute(
        "DROP TRIGGER ck_appointment_has_companion_insert ON appointment"
    )
    op.execute(
        "DROP TRIGGER ck_appointment_has_companion_remove "
        "ON appointment_companion"
    )
    op.execute("DROP FUNCTION require_appointment_companion()")


def downgrade() -> None:
    lonely = op.get_bind().execute(sa.text(
        "SELECT count(*) FROM appointment a WHERE NOT EXISTS ("
        "SELECT 1 FROM appointment_companion c "
        "WHERE c.appointment_id = a.id)"
    )).scalar_one()
    if lonely:
        raise RuntimeError(
            "Cannot downgrade: some appointments have no companion"
        )
    op.execute(_RULE)
    op.execute("""
        CREATE CONSTRAINT TRIGGER ck_appointment_has_companion_insert
        AFTER INSERT ON appointment
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW EXECUTE FUNCTION require_appointment_companion()
    """)
    op.execute("""
        CREATE CONSTRAINT TRIGGER ck_appointment_has_companion_remove
        AFTER DELETE OR UPDATE ON appointment_companion
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW EXECUTE FUNCTION require_appointment_companion()
    """)
