"""Deleting an account keeps the care it took part in, and never fails on it.

Two rules made the deletion of an account fail as soon as it had done some
care in a circle that stays (one with another manager):

  - Its dose records lose their recorder (ON DELETE SET NULL). That change
    ran the dose check again against the medicine as it is now, and a dose
    recorded before the medicine was changed or stopped no longer matched
    it. The check is about when a dose was due, so it now runs only when a
    dose's schedule or day changes.
  - It was the companion of an appointment (ON DELETE RESTRICT). Its
    companion rows now go with it, and an appointment whose only companion
    left this way stays, with no companion, in the circle's list and
    history; a manager can add one. Saving an appointment still needs one.

Revision ID: 0029
Revises: 0028
"""

from alembic import op
import sqlalchemy as sa

revision = "0029"
down_revision = "0028"
branch_labels = None
depends_on = None

_COMPANION_FK = "fk_appointment_companion_account_id_account"


def _dose_trigger(columns: str) -> None:
    op.execute(
        "DROP TRIGGER check_medication_dose_valid ON medication_dose_record"
    )
    op.execute(f"""
        CREATE CONSTRAINT TRIGGER check_medication_dose_valid
        AFTER INSERT OR UPDATE{columns} ON medication_dose_record
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW EXECUTE FUNCTION check_medication_dose()
    """)


def _companion_fk(ondelete: str) -> None:
    op.drop_constraint(
        _COMPANION_FK, "appointment_companion", type_="foreignkey"
    )
    op.create_foreign_key(
        _COMPANION_FK,
        "appointment_companion", "account", ["account_id"], ["id"],
        ondelete=ondelete,
    )


def _companion_rule(gone_account_allowed: bool) -> None:
    """The «at least one companion» rule; with `gone_account_allowed`, a
    companion removed with its deleted account does not count against it.

    The two IFs stay nested: PL/pgSQL plans a whole condition at once, and
    OLD.account_id only exists when the row is a companion's."""
    allowance = """
            IF TG_TABLE_NAME = 'appointment_companion' AND TG_OP = 'DELETE'
            THEN
                IF NOT EXISTS (
                    SELECT 1 FROM account WHERE id = OLD.account_id
                ) THEN
                    RETURN NULL;
                END IF;
            END IF;""" if gone_account_allowed else ""
    op.execute(f"""
        CREATE OR REPLACE FUNCTION require_appointment_companion()
        RETURNS trigger LANGUAGE plpgsql AS $$
        DECLARE appointment_key uuid;
        BEGIN{allowance}
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


def _appointment_trigger(events: str) -> None:
    """When an appointment itself is checked for a companion: only when it
    is made, once an appointment may have lost its last one; on every save
    before that."""
    op.execute(
        "DROP TRIGGER ck_appointment_has_companion_insert ON appointment"
    )
    op.execute(f"""
        CREATE CONSTRAINT TRIGGER ck_appointment_has_companion_insert
        AFTER {events} ON appointment
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW EXECUTE FUNCTION require_appointment_companion()
    """)


def upgrade() -> None:
    _dose_trigger(" OF schedule_id, scheduled_on")
    _companion_fk("CASCADE")
    _companion_rule(gone_account_allowed=True)
    # Closing or changing an appointment whose companion left must work:
    # a new one still needs a companion, and the companion rows are
    # checked whenever they change.
    _appointment_trigger("INSERT")


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
    _appointment_trigger("INSERT OR UPDATE")
    _companion_rule(gone_account_allowed=False)
    _companion_fk("RESTRICT")
    _dose_trigger("")
