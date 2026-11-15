"""The shapes of a demo medicine and its doses, and the summary at the
end."""

from dataclasses import dataclass, field

from app.demo_data.story import EVERY_DAY


@dataclass
class Summary:
    """What was made, for the message at the end."""

    circles: list[str] = field(default_factory=list)
    plans: int = 0
    revisions: int = 0
    taken: int = 0
    skipped: int = 0
    open_doses: int = 0


def dose_at(clock, dose, unit, days=EVERY_DAY, instructions=None):
    """One dose time of a demo medicine, in the shape the medicine request
    takes.
    """
    return {
        "time_of_day": clock,
        "dose_value": dose,
        "dose_unit": unit,
        "weekdays": list(days),
        "instructions": instructions,
    }


def medicine(name, strength, unit, form, schedules, starts, ends=None, **more):
    """One demo medicine, in the shape the medicine request takes."""
    return {
        "name": name,
        "strength_value": strength,
        "strength_unit": unit,
        "dosage_form": form,
        "treatment_starts_on": starts,
        "treatment_ends_on": ends,
        "schedules": schedules,
        **more,
    }
