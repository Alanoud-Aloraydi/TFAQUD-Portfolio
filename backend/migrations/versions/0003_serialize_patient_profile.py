"""Serialize linked-patient writes with concurrent account profile updates."""

from alembic import op

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None

_GUARD = """
CREATE OR REPLACE FUNCTION lock_care_parent() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    old_circle uuid;
    new_circle uuid;
BEGIN
    IF TG_OP <> 'INSERT' THEN old_circle := OLD.care_circle_id; END IF;
    IF TG_OP <> 'DELETE' THEN
        new_circle := NEW.care_circle_id;
        IF LOCK_ACCOUNT_CONDITION THEN
            PERFORM 1 FROM account WHERE id = NEW.account_id FOR UPDATE;
        END IF;
        IF TG_TABLE_NAME = 'care_circle_manager' AND NOT EXISTS (
            SELECT 1 FROM account WHERE id = NEW.account_id
            AND app_mode = 'detailed' AND first_name IS NOT NULL
        ) THEN
            RAISE EXCEPTION 'Managers require complete detailed accounts'
                USING ERRCODE = '23514';
        END IF;
    END IF;
    PERFORM 1 FROM care_circle
        WHERE id IN (old_circle, new_circle) ORDER BY id FOR UPDATE;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$;
"""


def upgrade():
    """Protect patient profile checks as well as manager checks."""
    op.execute(
        _GUARD.replace(
            "LOCK_ACCOUNT_CONDITION",
            "NEW.account_id IS NOT NULL",
        )
    )


def downgrade():
    """Restore the initial manager-only account locking behavior."""
    op.execute(
        _GUARD.replace(
            "LOCK_ACCOUNT_CONDITION",
            "TG_TABLE_NAME = 'care_circle_manager'",
        )
    )
