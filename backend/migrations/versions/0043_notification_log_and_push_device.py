"""The tick's log in columns, and a phone's token tied only to its sign-in.

- `notification_log` kept "kind:id:day[:time]" in one text. It now has a
  column for each part: `kind`, `target_id` (the dose time or the reading
  plan version), `scheduled_on`, and `time_of_day` for a reading. One row
  per (kind, target, day, time) still makes the tick send once.
- `push_device.account_id` copied what its sign-in already says
  (`account_session.account_id`), so it goes: the sign-in names the
  account. The token stays unique but is no longer the key: every table
  has a UUID key, and a natural key is a unique column.

Revision ID: 0043
Revises: 0042
"""
from alembic import op
import sqlalchemy as sa

revision = "0043"
down_revision = "0042"
branch_labels = None
depends_on = None

_KINDS = "('dose_missed', 'measurement_missed')"


def upgrade() -> None:
    log = "notification_log"
    for column, type_ in (
        ("kind", sa.Text()), ("target_id", sa.Uuid()),
        ("scheduled_on", sa.Date()), ("time_of_day", sa.Time()),
    ):
        op.add_column(log, sa.Column(column, type_))
    op.execute(
        f"UPDATE {log} SET kind = split_part(dedupe_key, ':', 1), "
        "target_id = split_part(dedupe_key, ':', 2)::uuid, "
        "scheduled_on = split_part(dedupe_key, ':', 3)::date, "
        "time_of_day = CASE WHEN split_part(dedupe_key, ':', 4) = '' "
        "THEN NULL ELSE (split_part(dedupe_key, ':', 4) || ':' || "
        "split_part(dedupe_key, ':', 5))::time END"
    )
    for column in ("kind", "target_id", "scheduled_on"):
        op.alter_column(log, column, nullable=False)
    op.drop_constraint("uq_notification_log_dedupe_key", log, type_="unique")
    op.drop_constraint(
        op.f("ck_notification_log_dedupe_key_nonblank"), log, type_="check"
    )
    op.drop_column(log, "dedupe_key")
    op.create_check_constraint(
        op.f("ck_notification_log_kind"), log, f"kind IN {_KINDS}"
    )
    op.create_check_constraint(
        op.f("ck_notification_log_time_of_day"), log,
        "(kind = 'measurement_missed') = (time_of_day IS NOT NULL)",
    )
    op.create_index(
        "uq_notification_log_kind_target_id_scheduled_on_time_of_day", log,
        ["kind", "target_id", "scheduled_on", "time_of_day"], unique=True,
        postgresql_nulls_not_distinct=True,
    )
    op.create_index(op.f("ix_notification_log_sent_at"), log, ["sent_at"])

    device = "push_device"
    op.drop_index("ix_push_device_account_id", table_name=device)
    op.drop_constraint(
        "fk_push_device_account_id_account", device, type_="foreignkey"
    )
    op.drop_column(device, "account_id")
    op.drop_constraint("pk_push_device", device, type_="primary")
    op.add_column(
        device,
        sa.Column(
            "id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
    )
    op.create_primary_key(op.f("pk_push_device"), device, ["id"])
    op.create_unique_constraint(
        op.f("uq_push_device_token"), device, ["token"]
    )
    for column in ("created_at", "updated_at"):
        op.alter_column(device, column, server_default=sa.text("now()"))


def downgrade() -> None:
    device = "push_device"
    for column in ("created_at", "updated_at"):
        op.alter_column(device, column, server_default=None)
    op.drop_constraint(op.f("uq_push_device_token"), device, type_="unique")
    op.drop_constraint(op.f("pk_push_device"), device, type_="primary")
    op.drop_column(device, "id")
    op.create_primary_key("pk_push_device", device, ["token"])
    op.add_column(device, sa.Column("account_id", sa.Uuid()))
    op.execute(
        "UPDATE push_device d SET account_id = s.account_id "
        "FROM account_session s WHERE s.id = d.session_id"
    )
    op.alter_column(device, "account_id", nullable=False)
    op.create_foreign_key(
        "fk_push_device_account_id_account", device, "account", ["account_id"],
        ["id"], ondelete="CASCADE",
    )
    op.create_index("ix_push_device_account_id", device, ["account_id"])

    log = "notification_log"
    op.drop_index(op.f("ix_notification_log_sent_at"), table_name=log)
    op.drop_index(
        "uq_notification_log_kind_target_id_scheduled_on_time_of_day",
        table_name=log,
    )
    op.add_column(log, sa.Column("dedupe_key", sa.Text()))
    op.execute(
        f"UPDATE {log} SET dedupe_key = kind || ':' || target_id || ':' || "
        "scheduled_on || COALESCE(':' || to_char(time_of_day, 'HH24:MI'), '')"
    )
    op.alter_column(log, "dedupe_key", nullable=False)
    for check in ("time_of_day", "kind"):
        op.drop_constraint(
            op.f(f"ck_notification_log_{check}"), log, type_="check"
        )
    for column in ("time_of_day", "scheduled_on", "target_id", "kind"):
        op.drop_column(log, column)
    op.create_check_constraint(
        op.f("ck_notification_log_dedupe_key_nonblank"), log,
        "length(btrim(dedupe_key)) > 0",
    )
    op.create_unique_constraint(
        "uq_notification_log_dedupe_key", log, ["dedupe_key"]
    )
