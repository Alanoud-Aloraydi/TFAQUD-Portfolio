"""One photo table per owner.

`photo` held the photo of an account, of a patient's circle or of a
medicine in one row with three owner columns, two of them always empty.
Each owner has its own table now, keyed by the owner (one photo each,
deleted with it): `account_photo`, `care_circle_photo` (a patient without
an account; a patient with one shares the account's photo) and
`medication_plan_photo`.

Revision ID: 0042
Revises: 0041
"""
from alembic import op
import sqlalchemy as sa

revision = "0042"
down_revision = "0041"
branch_labels = None
depends_on = None

_OWNERS = (
    ("account_photo", "account_id", "account"),
    ("care_circle_photo", "care_circle_id", "care_circle"),
    ("medication_plan_photo", "medication_plan_id", "medication_plan"),
)
_BOUND = "octet_length(data) BETWEEN 1 AND 4194304"


def upgrade() -> None:
    for table, column, owner in _OWNERS:
        op.create_table(
            table,
            sa.Column(column, sa.Uuid(), nullable=False),
            sa.Column("data", sa.LargeBinary(), nullable=False),
            sa.CheckConstraint(_BOUND, name=op.f(f"ck_{table}_data_size")),
            sa.ForeignKeyConstraint(
                [column], [f"{owner}.id"], ondelete="CASCADE",
                name=op.f(f"fk_{table}_{column}_{owner}"),
            ),
            sa.PrimaryKeyConstraint(column, name=op.f(f"pk_{table}")),
        )
        op.execute(
            f"INSERT INTO {table} ({column}, data) "
            f"SELECT {column}, data FROM photo WHERE {column} IS NOT NULL"
        )
    op.drop_table("photo")


def downgrade() -> None:
    op.create_table(
        "photo",
        sa.Column(
            "id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("account_id", sa.Uuid()),
        sa.Column("care_circle_id", sa.Uuid()),
        sa.Column("medication_plan_id", sa.Uuid()),
        sa.Column("data", sa.LargeBinary(), nullable=False),
        sa.CheckConstraint(
            "num_nonnulls(account_id, care_circle_id, medication_plan_id) = 1",
            name=op.f("ck_photo_one_owner"),
        ),
        sa.CheckConstraint(_BOUND, name=op.f("ck_photo_bounded_data")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_photo")),
        *(
            sa.ForeignKeyConstraint(
                [column], [f"{owner}.id"], ondelete="CASCADE",
                name=op.f(f"fk_photo_{column}_{owner}"),
            )
            for _, column, owner in _OWNERS
        ),
        *(
            sa.UniqueConstraint(column, name=op.f(f"uq_photo_{column}"))
            for _, column, _ in _OWNERS
        ),
    )
    for table, column, _ in _OWNERS:
        op.execute(
            f"INSERT INTO photo ({column}, data) SELECT {column}, data "
            f"FROM {table}"
        )
        op.drop_table(table)
