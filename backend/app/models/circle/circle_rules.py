"""The database rules of a care circle."""

from sqlalchemy import CheckConstraint

from app.models.circle.codes import AVATARS_SQL, BLOOD_SQL

CIRCLE_TABLE_ARGS = (
    # Without an account the name is the managers' choice, or none (0067).
    CheckConstraint(
        "(account_id IS NOT NULL AND name IS NOT NULL "
        "AND first_name IS NULL AND last_name IS NULL "
        "AND avatar_code IS NULL AND birth_date IS NULL "
        "AND city IS NULL) OR (account_id IS NULL "
        "AND first_name IS NOT NULL AND last_name IS NOT NULL "
        "AND birth_date IS NOT NULL AND city IS NOT NULL)",
        name="account_source",
    ),
    CheckConstraint(
        "name IS NULL OR length(btrim(name)) BETWEEN 1 AND 60",
        name="name",
    ),
    CheckConstraint(
        "first_name IS NULL OR length(btrim(first_name)) BETWEEN 1 AND 50",
        name="first_name",
    ),
    CheckConstraint(
        "last_name IS NULL OR length(btrim(last_name)) BETWEEN 1 AND 50",
        name="last_name",
    ),
    CheckConstraint(
        "city IS NULL OR length(btrim(city)) BETWEEN 1 AND 60",
        name="city",
    ),
    CheckConstraint(
        "birth_date IS NULL OR birth_date >= DATE '1900-01-01'",
        name="birth_date",
    ),
    CheckConstraint(
        "length(btrim(time_zone)) BETWEEN 1 AND 64", name="time_zone"
    ),
    CheckConstraint("latitude BETWEEN -90 AND 90", name="latitude"),
    CheckConstraint("longitude BETWEEN -180 AND 180", name="longitude"),
    CheckConstraint(f"blood_type IN ({BLOOD_SQL})", name="blood_type"),
    CheckConstraint(
        f"avatar_code IS NULL OR avatar_code IN ({AVATARS_SQL})",
        name="avatar_code",
    ),
    CheckConstraint(
        "conditions_status IS NULL OR "
        "conditions_status IN ('none', 'listed')",
        name="conditions_status",
    ),
    CheckConstraint(
        "allergies_status IS NULL OR "
        "allergies_status IN ('none', 'listed')",
        name="allergies_status",
    ),
)
