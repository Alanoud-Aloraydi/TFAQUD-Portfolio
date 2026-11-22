"""The database rules of an appointment."""

from sqlalchemy import CheckConstraint, Index

from app.appointments.kinds import kinds_sql

APPOINTMENT_TABLE_ARGS = (
    CheckConstraint(
        f"kind IN ({kinds_sql()})",
        name="kind",
    ),
    CheckConstraint(
        "(kind = 'other' AND other_text IS NOT NULL AND "
        "length(btrim(other_text)) > 0 AND "
        "char_length(other_text) <= 80) OR "
        "(kind <> 'other' AND other_text IS NULL)",
        name="other_text",
    ),
    CheckConstraint(
        "status IN ('scheduled', 'completed', 'cancelled')",
        name="status",
    ),
    # «فائت» chosen from «السجل» leaves a visit open (migration 0070).
    CheckConstraint(
        "NOT marked_missed OR status = 'scheduled'",
        name="marked_missed",
    ),
    CheckConstraint(
        "(kind = 'remote' AND remote_method IS NOT NULL "
        "AND remote_method IN ('video', 'phone') "
        "AND place IS NULL) OR (kind <> 'remote' AND "
        "remote_method IS NULL AND place IS NOT NULL AND "
        "length(btrim(place)) > 0)",
        name="location_shape",
    ),
    CheckConstraint(
        "specialty IS NULL OR (length(btrim(specialty)) > 0 AND "
        "char_length(specialty) <= 80)",
        name="specialty",
    ),
    CheckConstraint(
        "place IS NULL OR char_length(place) <= 160",
        name="place_length",
    ),
    Index(
        "ix_appointment_care_circle_id_scheduled_on_time_of_day",
        "care_circle_id", "scheduled_on", "time_of_day",
    ),
)
