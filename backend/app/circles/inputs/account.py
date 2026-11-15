"""The body of deleting one's account."""

from typing import Literal

from app.circles.inputs.fields import Flag
from app.validation import Dto


class DeleteAccountInput(Dto):
    """The body of deleting one's account: a patient chooses whether their
    circle is deleted or its care continues, and the last manager of a circle
    confirms its deletion.
    """

    patient_choice: Literal["delete", "continue"] | None = None
    delete_last_managed_circles: Flag = False
