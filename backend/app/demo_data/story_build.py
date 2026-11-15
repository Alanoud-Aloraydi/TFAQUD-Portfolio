"""The whole demo story, in the order it happened."""

from app.care import CareService
from app.demo_data.shapes import Summary
from app.medications.plans import MedicationPlanService


class DemoStory:
    """Builds the story."""

    def build(self) -> Summary:
        """Make the whole demo: Lina's own care; her mother's circle (no
        account, every kind of medicine); Sara's grandfather's circle, which
        Sara invites Lina to manage; a request waiting for Lina's father; and
        her uncle Khaled's circle in simplified mode.
        """
        lina, sara, khaled = self.accounts()
        care = CareService(self.session, self.at(-60))
        own = self._lina_own(lina, care)
        mother = self._mother(lina, care)
        revise_metformin = self._mother_daily(lina, mother)
        self._mother_weekly(lina, mother)
        aspirin = self._mother_courses(lina, mother)
        grandfather = self._grandfather(sara, lina)
        self._waiting(lina, mother)

        # The stop and the coming change first, so the dose history follows
        # them: the stopped medicine has no doses after it stopped.
        MedicationPlanService(self.session, self.at(-3, 15)).stop(
            mother.id, aspirin.id, lina.id
        )
        plan, later = revise_metformin
        self.revise(lina, mother, plan, 1, later, self.day(5), self.now)

        self.mother_checks(lina, mother)
        uncle = self.uncle(lina, sara, khaled)
        aunt = self.aunt(lina)

        # The doses of the past month.
        self.history(lina, own)
        self.history(lina, mother)
        self.history(sara, grandfather)
        self.history(lina, uncle)
        self.history(lina, aunt)

        self.summary.circles = [
            "رعايتي",
            "دائرة نورة",
            "دائرة عبدالله",
            "دائرة هدى",
            "دائرة خالد",
        ]
        return self.summary
