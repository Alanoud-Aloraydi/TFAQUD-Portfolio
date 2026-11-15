"""The database rules of a circle request."""

from sqlalchemy import CheckConstraint, Index, text

from app.models.circle_request.formats import PHONE_FORMAT

REQUEST_TABLE_ARGS = (
    CheckConstraint(
        f"patient_phone_number {PHONE_FORMAT}", name="phone_format"
    ),
    CheckConstraint(
        "proposed_app_mode IN ('detailed', 'simplified')",
        name="proposed_app_mode",
    ),
    CheckConstraint(
        "status IN ('pending', 'accepted', 'completed', 'declined', "
        "'cancelled', 'superseded')",
        name="status",
    ),
    CheckConstraint(
        "(status = 'completed' AND care_circle_id IS NOT NULL "
        "AND completed_at IS NOT NULL) OR "
        "(status <> 'completed' AND care_circle_id IS NULL "
        "AND completed_at IS NULL)",
        name="completion",
    ),
    CheckConstraint(
        "status <> 'accepted' OR (responded_by_account_id IS NOT NULL "
        "AND responded_at IS NOT NULL)",
        name="consent",
    ),
    Index(
        "uq_care_circle_request_requested_by_patient_phone_number_open",
        "requested_by_account_id",
        "patient_phone_number",
        unique=True,
        postgresql_where=text("status IN ('pending', 'accepted')"),
    ),
    Index(
        "uq_care_circle_request_responded_by_account_id_accepted",
        "responded_by_account_id",
        unique=True,
        postgresql_where=text("status = 'accepted'"),
    ),
    Index(
        "ix_care_circle_request_patient_phone_number",
        "patient_phone_number",
    ),
)
