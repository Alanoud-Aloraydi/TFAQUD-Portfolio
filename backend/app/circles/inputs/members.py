"""The bodies about members: what each edits, the lead, leaving,
inviting, asking and answering."""

from uuid import UUID

from pydantic import model_validator

from app.auth.inputs import Phone
from app.circles.inputs.fields import AppMode, Flag
from app.validation import Dto


class EditAreasInput(Dto):
    """What a member may edit, area by area; an area left out stays."""

    medications: Flag | None = None
    measurements: Flag | None = None
    appointments: Flag | None = None


class MemberAccessInput(Dto):
    """The leader's edit permissions for one member: per area
    (`edit_access`), or `can_edit` for all three at once (the app before
    the areas sends it)."""

    edit_access: EditAreasInput | None = None
    can_edit: Flag | None = None

    @model_validator(mode="after")
    def one_form(self):
        """Exactly one of the two."""
        if (self.edit_access is None) == (self.can_edit is None):
            raise ValueError("Send either edit_access or can_edit.")
        return self

    def areas(self) -> dict[str, bool]:
        """The areas to change, with their new value."""
        if self.can_edit is not None:
            return {
                area: self.can_edit
                for area in ("medications", "measurements", "appointments")
            }
        return self.edit_access.model_dump(exclude_none=True)


class LeaderInput(Dto):
    """The member the leader hands the circle to."""

    account_id: UUID


class LeaveCircleInput(Dto):
    """The body of leaving a circle; the last manager must also confirm its
    deletion.
    """

    confirm_delete: Flag = False


class InviteInput(Dto):
    """The body of inviting another manager by phone number."""

    invitee_phone_number: Phone


class RespondInput(Dto):
    """The body of answering a request or an invitation: accept or decline."""

    accept: Flag


class CircleRequestInput(Dto):
    """The body of asking a patient to make their circle."""

    patient_phone_number: Phone
    proposed_app_mode: AppMode
