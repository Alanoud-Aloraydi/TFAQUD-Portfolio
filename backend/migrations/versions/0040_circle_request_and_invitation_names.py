"""A circle request and a circle invitation, named as the API names them.

- `care_circle_creation_request` is `care_circle_request` (the API path is
  /circle-requests) and `care_circle_manager_invitation` is
  `care_circle_invitation` (/invitations).
- Their status `canceled` is `cancelled`, the spelling an appointment's
  status and a medicine version's `cancelled_at` use.
- `proposed_circle_label` goes: the patient names the circle when they
  complete the request, and nothing read the label since.
- Their indexes are named after the table and every column they cover.

Revision ID: 0040
Revises: 0039
"""
from alembic import op
import sqlalchemy as sa

revision = "0040"
down_revision = "0039"
branch_labels = None
depends_on = None

_REQUEST_OLD, _REQUEST = "care_circle_creation_request", "care_circle_request"
_INVITE_OLD, _INVITE = (
    "care_circle_manager_invitation", "care_circle_invitation"
)
_REQUEST_STATUS = (
    "status IN ('pending', 'accepted', 'completed', 'declined', "
    "'{cancelled}', 'superseded')"
)
_INVITE_STATUS = (
    "status IN ('pending', 'accepted', 'declined', '{cancelled}')"
)
# (table after the rename, old name, new name) for constraints.
_CONSTRAINTS = (
    (_REQUEST, "pk_care_circle_creation_request", "pk_care_circle_request"),
    (_REQUEST, "fk_care_circle_creation_request_care_circle_id_care_circle",
     "fk_care_circle_request_care_circle_id_care_circle"),
    (_REQUEST,
     "fk_care_circle_creation_request_requested_by_account_id_account",
     "fk_care_circle_request_requested_by_account_id_account"),
    (_REQUEST,
     "fk_care_circle_creation_request_responded_by_account_id_account",
     "fk_care_circle_request_responded_by_account_id_account"),
    (_REQUEST, "uq_care_circle_creation_request_care_circle_id",
     "uq_care_circle_request_care_circle_id"),
    (_REQUEST, "ck_care_circle_creation_request_completion",
     "ck_care_circle_request_completion"),
    (_REQUEST, "ck_care_circle_creation_request_consent",
     "ck_care_circle_request_consent"),
    (_REQUEST, "ck_care_circle_creation_request_phone_format",
     "ck_care_circle_request_phone_format"),
    (_REQUEST, "ck_care_circle_creation_request_mode",
     "ck_care_circle_request_proposed_app_mode"),
    (_INVITE, "pk_care_circle_manager_invitation",
     "pk_care_circle_invitation"),
    (_INVITE,
     "fk_care_circle_manager_invitation_care_circle_id_care_circle",
     "fk_care_circle_invitation_care_circle_id_care_circle"),
    (_INVITE,
     "fk_care_circle_manager_invitation_invited_by_account_id_account",
     "fk_care_circle_invitation_invited_by_account_id_account"),
    (_INVITE,
     "fk_care_circle_manager_invitation_responded_by_account_id_account",
     "fk_care_circle_invitation_responded_by_account_id_account"),
    (_INVITE, "ck_care_circle_manager_invitation_phone_format",
     "ck_care_circle_invitation_phone_format"),
)
_INDEXES = (
    ("ix_care_circle_creation_request_requested_by_account_id",
     "ix_care_circle_request_requested_by_account_id"),
    ("ix_care_circle_creation_request_responded_by_account_id",
     "ix_care_circle_request_responded_by_account_id"),
    ("ix_creation_request_target",
     "ix_care_circle_request_patient_phone_number"),
    ("uq_creation_request_accepted",
     "uq_care_circle_request_responded_by_account_id_accepted"),
    ("uq_creation_request_active",
     "uq_care_circle_request_requested_by_patient_phone_number_open"),
    ("ix_care_circle_manager_invitation_care_circle_id",
     "ix_care_circle_invitation_care_circle_id"),
    ("ix_care_circle_manager_invitation_invited_by_account_id",
     "ix_care_circle_invitation_invited_by_account_id"),
    ("ix_care_circle_manager_invitation_responded_by_account_id",
     "ix_care_circle_invitation_responded_by_account_id"),
    ("ix_manager_invitation_target",
     "ix_care_circle_invitation_invitee_phone_number"),
    ("uq_manager_invitation_pending",
     "uq_care_circle_invitation_circle_invitee_phone_number_pending"),
)


def _status(table, old_check, new_check, rule, frm, to):
    op.drop_constraint(op.f(old_check), table, type_="check")
    op.execute(f"UPDATE {table} SET status = '{to}' WHERE status = '{frm}'")
    op.create_check_constraint(
        op.f(new_check), table, rule.format(cancelled=to)
    )


def _rename_constraint(table, old, new):
    # Use the same name truncation as CREATE TABLE for long constraint names.
    preparer = op.get_bind().dialect.identifier_preparer
    old_name = preparer.truncate_and_render_constraint_name(op.f(old))
    new_name = preparer.truncate_and_render_constraint_name(op.f(new))
    op.execute(
        f"ALTER TABLE {table} RENAME CONSTRAINT {old_name} TO {new_name}"
    )


def upgrade() -> None:
    op.rename_table(_REQUEST_OLD, _REQUEST)
    op.rename_table(_INVITE_OLD, _INVITE)
    for table, old, new in _CONSTRAINTS:
        _rename_constraint(table, old, new)
    for old, new in _INDEXES:
        op.execute(f"ALTER INDEX {old} RENAME TO {new}")
    _status(_REQUEST, "ck_care_circle_creation_request_status",
            "ck_care_circle_request_status", _REQUEST_STATUS,
            "canceled", "cancelled")
    _status(_INVITE, "ck_care_circle_manager_invitation_status",
            "ck_care_circle_invitation_status", _INVITE_STATUS,
            "canceled", "cancelled")
    op.drop_constraint(
        op.f("ck_care_circle_creation_request_label"), _REQUEST, type_="check"
    )
    op.drop_column(_REQUEST, "proposed_circle_label")


def downgrade() -> None:
    op.add_column(
        _REQUEST,
        sa.Column(
            "proposed_circle_label", sa.Text(), nullable=False,
            server_default="دائرة",
        ),
    )
    op.alter_column(_REQUEST, "proposed_circle_label", server_default=None)
    op.create_check_constraint(
        op.f("ck_care_circle_creation_request_label"), _REQUEST,
        "length(btrim(proposed_circle_label)) > 0",
    )
    _status(_INVITE, "ck_care_circle_invitation_status",
            "ck_care_circle_manager_invitation_status", _INVITE_STATUS,
            "cancelled", "canceled")
    _status(_REQUEST, "ck_care_circle_request_status",
            "ck_care_circle_creation_request_status", _REQUEST_STATUS,
            "cancelled", "canceled")
    for old, new in _INDEXES:
        op.execute(f"ALTER INDEX {new} RENAME TO {old}")
    for table, old, new in _CONSTRAINTS:
        _rename_constraint(table, new, old)
    op.rename_table(_INVITE, _INVITE_OLD)
    op.rename_table(_REQUEST, _REQUEST_OLD)
