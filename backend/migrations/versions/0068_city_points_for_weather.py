"""Circles whose city is in the app's list get that city's point, so the
patient's weather shows on «اليوم». Until now only a point the app sent
was kept, and the app sends none, so only the demo circles had one.

Revision ID: 0068
Revises: 0067
"""
import sqlalchemy as sa
from alembic import op

from app.care.city_points import CITY_POINTS

revision = "0068"
down_revision = "0067"
branch_labels = None
depends_on = None

# The city is on the circle when its patient has no account, else on the
# patient's account.
_FILL = sa.text(
    "UPDATE care_circle AS c SET latitude = :lat, longitude = :lon "
    "WHERE c.latitude IS NULL AND ("
    "(c.account_id IS NULL AND btrim(c.city) = :city) OR "
    "EXISTS (SELECT 1 FROM account AS a WHERE a.id = c.account_id "
    "AND btrim(a.city) = :city))"
)


def upgrade() -> None:
    for city, (lat, lon) in CITY_POINTS.items():
        op.execute(_FILL.bindparams(city=city, lat=lat, lon=lon))


def downgrade() -> None:
    # Nothing to undo: a point filled here cannot be told from one the app
    # sent, and a point does no harm.
    pass
