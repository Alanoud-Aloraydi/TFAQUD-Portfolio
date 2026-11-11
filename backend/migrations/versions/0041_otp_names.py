"""A sign-in code request and its sends, named as the server names them.

`otp_challenge` is `otp_request` (the server's `OtpRequest`, the API's
`request_id`) and `otp_send_attempt` is `otp_send`, pointing at its request
by `otp_request_id`. `attempt_count` counted wrong codes, so it is
`wrong_try_count` (the server's `wrong_tries`). Every constraint and index
of the two tables takes the new table name; the hand-made index names say
the columns they cover.

Revision ID: 0041
Revises: 0040
"""
from alembic import op

revision = "0041"
down_revision = "0040"
branch_labels = None
depends_on = None

_TABLES = (("otp_challenge", "otp_request"), ("otp_send_attempt", "otp_send"))
_INDEXES = (
    ("uq_otp_request_pending_phone", "uq_otp_request_phone_number_pending"),
    ("ix_otp_send_challenge_time", "ix_otp_send_otp_request_id_created_at"),
    ("ix_otp_send_device_time", "ix_otp_send_device_id_created_at"),
    ("ix_otp_send_ip_time", "ix_otp_send_client_ip_created_at"),
)
_CONSTRAINTS = (
    ("otp_send", "fk_otp_send_challenge_id_otp_challenge",
     "fk_otp_send_otp_request_id_otp_request"),
    ("otp_request", "ck_otp_request_attempt_count",
     "ck_otp_request_wrong_try_count"),
)


def rename_by_prefix(table: str, old: str, new: str) -> str:
    """SQL that renames every constraint and index of `table` whose name
    holds `old` so that it holds `new` instead."""
    return f"""
    DO $$
    DECLARE item record;
    BEGIN
        FOR item IN
            SELECT conname AS name FROM pg_constraint
            WHERE conrelid = '{table}'::regclass AND conname LIKE '%{old}%'
        LOOP
            EXECUTE format('ALTER TABLE {table} RENAME CONSTRAINT %I TO %I',
                item.name, replace(item.name, '{old}', '{new}'));
        END LOOP;
        FOR item IN
            SELECT indexname AS name FROM pg_indexes
            WHERE tablename = '{table}' AND indexname LIKE '%{old}%'
              AND NOT EXISTS (
                  SELECT 1 FROM pg_constraint WHERE conname = indexname
              )
        LOOP
            EXECUTE format('ALTER INDEX %I RENAME TO %I',
                item.name, replace(item.name, '{old}', '{new}'));
        END LOOP;
    END $$;
    """


def upgrade() -> None:
    for old, new in _TABLES:
        op.rename_table(old, new)
        op.execute(rename_by_prefix(new, old, new))
    op.alter_column(
        "otp_request", "attempt_count", new_column_name="wrong_try_count"
    )
    op.alter_column(
        "otp_send", "challenge_id", new_column_name="otp_request_id"
    )
    for table, old, new in _CONSTRAINTS:
        op.execute(f"ALTER TABLE {table} RENAME CONSTRAINT {old} TO {new}")
    for old, new in _INDEXES:
        op.execute(f"ALTER INDEX {old} RENAME TO {new}")


def downgrade() -> None:
    for old, new in _INDEXES:
        op.execute(f"ALTER INDEX {new} RENAME TO {old}")
    for table, old, new in _CONSTRAINTS:
        op.execute(f"ALTER TABLE {table} RENAME CONSTRAINT {new} TO {old}")
    op.alter_column(
        "otp_send", "otp_request_id", new_column_name="challenge_id"
    )
    op.alter_column(
        "otp_request", "wrong_try_count", new_column_name="attempt_count"
    )
    for old, new in reversed(_TABLES):
        op.execute(rename_by_prefix(new, new, old))
        op.rename_table(new, old)
