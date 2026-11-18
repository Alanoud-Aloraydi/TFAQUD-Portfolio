"""What `flask keep-only` prints before it deletes anything."""

from app.keep_only.plan import KeepPlan
from app.models import Account, CareCircle


def plan_lines(plan: KeepPlan) -> list[str]:
    """The kept accounts, then everything that goes, one line each."""
    lines = [f"Kept ({len(plan.keep)} numbers):"]
    lines += [f"  {_person(person)}" for person in plan.kept]
    lines += [f"  {phone}  (no account yet)" for phone in plan.missing]
    lines.append(f"Accounts to delete ({len(plan.accounts)}):")
    lines += [f"  {_person(person)}" for person in plan.accounts]
    lines.append(f"Circles to delete, whole ({len(plan.circles)}):")
    lines += [f"  {_circle(circle)}" for circle in plan.circles]
    lines += [
        f"Invitations to other numbers: {plan.invitations}",
        f"Circle requests to or from other numbers: {plan.requests}",
        f"Sign-in codes of other numbers: {plan.sign_ins}",
    ]
    return lines


def _person(person: Account) -> str:
    """The number and the name of an account."""
    name = " ".join(
        part for part in (person.first_name, person.last_name) if part
    )
    return f"{person.phone_number}  {name or '(no name yet)'}"


def _circle(circle: CareCircle) -> str:
    """A circle as the app names it: its own name, or its patient's."""
    patient = " ".join(
        part for part in (circle.first_name, circle.last_name) if part
    )
    return circle.name or patient or "(the patient's own circle)"
