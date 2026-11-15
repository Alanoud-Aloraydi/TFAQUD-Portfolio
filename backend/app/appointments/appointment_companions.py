"""Who goes with the patient: checked against the members, and replaced."""

from uuid import UUID

from sqlalchemy import delete, select

from app.errors import ValidationFailed
from app.models import Account, CareCircleManager
from app.models.appointment import AppointmentCompanion


class AppointmentCompanions:
    """Checks and replaces companions."""

    def _companions(self, circle_id: UUID, account_ids: list[UUID]) -> None:
        """422 unless every companion is a manager of the circle with an
        account (their rows are locked meanwhile). No companion is fine.
        """
        if not account_ids:
            return
        members = set(self.session.scalars(
            select(CareCircleManager.account_id)
            .join(Account, Account.id == CareCircleManager.account_id)
            .where(
                CareCircleManager.care_circle_id == circle_id,
                CareCircleManager.account_id.in_(account_ids),
            )
            .with_for_update()
        ))
        if members != set(account_ids):
            raise ValidationFailed(code="appointment_invalid_companion")

    def _replace_companions(
        self, appointment_id: UUID, account_ids: list[UUID]
    ) -> None:
        """Make the appointment's companions exactly these accounts."""
        self.session.execute(
            delete(AppointmentCompanion).where(
                AppointmentCompanion.appointment_id == appointment_id
            )
        )
        self.session.add_all(
            AppointmentCompanion(
                appointment_id=appointment_id, account_id=account_id
            )
            for account_id in account_ids
        )
        self.session.flush()
