"""Every patient has their own IANA time zone.

A circle's schedules, its "today" and its birth-date check follow the
place where the patient lives, whoever records and wherever their phone
is. Every patient made before this revision lived by Asia/Riyadh, the one
zone the server knew, so they keep it. The column has no default: the
server always names the zone when it makes a patient.

The database checks only that the zone is not blank; the server checks it
is a real IANA zone (`app.clock.is_zone`), because PostgreSQL's zone list
can differ from Python's.

Revision ID: 0030
Revises: 0029
"""

from alembic import op
import sqlalchemy as sa

revision = "0030"
down_revision = "0029"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "patient",
        sa.Column(
            "time_zone",
            sa.Text(),
            nullable=False,
            server_default="Asia/Riyadh",
        ),
    )
    op.alter_column("patient", "time_zone", server_default=None)
    op.create_check_constraint(
        "time_zone_nonblank",
        "patient",
        "length(btrim(time_zone)) > 0",
    )


def downgrade() -> None:
    """Refuse when a patient lives outside Asia/Riyadh: the older server
    would move their whole schedule to Riyadh time."""
    elsewhere = op.get_bind().execute(sa.text(
        "SELECT count(*) FROM patient WHERE time_zone <> 'Asia/Riyadh'"
    )).scalar_one()
    if elsewhere:
        raise RuntimeError(
            "Cannot downgrade: some patients live outside Asia/Riyadh"
        )
    op.drop_constraint(
        "time_zone_nonblank", "patient", type_="check"
    )
    op.drop_column("patient", "time_zone")
