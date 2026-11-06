"""Record who asked for each sign-in code (the device and the IP).

The server caps the codes one device and one IP may ask for in an hour, so
one phone or one network cannot send codes to many numbers.

Revision ID: 0020
Revises: 0019
"""

from alembic import op
import sqlalchemy as sa

revision = "0020"
down_revision = "0019"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "otp_send_attempt", sa.Column("device_id", sa.Text(), nullable=True)
    )
    op.add_column(
        "otp_send_attempt", sa.Column("client_ip", sa.Text(), nullable=True)
    )
    op.create_index(
        "ix_otp_send_attempt_device_time",
        "otp_send_attempt",
        ["device_id", "created_at"],
    )
    op.create_index(
        "ix_otp_send_attempt_ip_time",
        "otp_send_attempt",
        ["client_ip", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_otp_send_attempt_ip_time", table_name="otp_send_attempt")
    op.drop_index(
        "ix_otp_send_attempt_device_time", table_name="otp_send_attempt"
    )
    op.drop_column("otp_send_attempt", "client_ip")
    op.drop_column("otp_send_attempt", "device_id")
