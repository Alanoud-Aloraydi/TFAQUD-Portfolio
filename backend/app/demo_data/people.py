"""The demo accounts and the medical files of their circles."""

from app.circles.inputs import MedicalProfileInput
from app.demo_accounts import DEMO_ACCOUNTS
from app.medical import MedicalService
from app.models import Account, CareCircle


class DemoPeople:
    """Makes the people and their files."""

    def accounts(self) -> list[Account]:
        """Make the demo accounts (Lina, Sara and Khaled)."""
        rows = [
            Account(
                phone_number=phone,
                first_name=first,
                last_name=last,
                display_name=display,
                birth_date=birth_date,
                city=city,
            )
            for phone, first, last, display, birth_date, city in DEMO_ACCOUNTS
        ]
        self.session.add_all(rows)
        self.session.flush()
        return rows

    def medical(self, actor: Account, circle: CareCircle, profile: dict):
        """Fill a demo patient's medical profile, as written two months ago."""
        MedicalService(self.session, self.at(-60)).update_profile(
            actor.id,
            circle.id,
            MedicalProfileInput.model_validate(profile).to_update(),
        )
