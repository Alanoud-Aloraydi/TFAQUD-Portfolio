"""Database initialization shared by models, migrations, and adapters."""

from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import MetaData
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Use stable constraint names for migrations and error reporting."""

    metadata = MetaData(
        naming_convention={
            "ix": "ix_%(table_name)s_%(column_0_name)s",
            "uq": "uq_%(table_name)s_%(column_0_name)s",
            "ck": "ck_%(table_name)s_%(constraint_name)s",
            "fk": (
                "fk_%(table_name)s_%(column_0_name)s_"
                "%(referred_table_name)s"
            ),
            "pk": "pk_%(table_name)s",
        }
    )


db = SQLAlchemy(model_class=Base)
migrate = Migrate(compare_type=True)


def initialize_database(app) -> bool:
    """Initialize configured PostgreSQL; unit-test fakes need no database."""
    from app import models  # noqa: F401 -- register all migration metadata

    if not app.config.get("SQLALCHEMY_DATABASE_URI"):
        return False
    db.init_app(app)
    migrate.init_app(app, db)
    return True
