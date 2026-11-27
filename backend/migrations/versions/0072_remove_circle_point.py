"""Remove the circle's point.

`care_circle.latitude` and `longitude` were the patient city's centre, for
the weather on «اليوم». The weather now follows the account's own city,
whose centre the server reads from the city list (`app.cities`), so nothing
reads the circle's point. Its range checks go with it.

Going back makes the two columns and their checks again, empty: the points
this removes do not come back.

Revision ID: 0072
Revises: 0071
"""

from alembic import op
import sqlalchemy as sa

revision = "0072"
down_revision = "0071"
branch_labels = None
depends_on = None

CHECKS = {
    "latitude": "latitude BETWEEN -90 AND 90",
    "longitude": "longitude BETWEEN -180 AND 180",
}


def upgrade():
    for column in CHECKS:
        op.drop_constraint(op.f(f"ck_care_circle_{column}"), "care_circle",
                           type_="check")
        op.drop_column("care_circle", column)


def downgrade():
    for column, check in CHECKS.items():
        op.add_column("care_circle",
                      sa.Column(column, sa.Double(), nullable=True))
        op.create_check_constraint(op.f(f"ck_care_circle_{column}"),
                                   "care_circle", check)
