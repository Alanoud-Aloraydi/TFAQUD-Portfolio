"""Keeping only some accounts on a test server, before testers come:
`flask --app wsgi keep-only NUMBER... [--yes]`.

Every account whose number is not kept goes, with every circle that has
such a person in it. Without --yes it only says what would be deleted.
Never in production."""

from collections.abc import Collection
from dataclasses import dataclass
from datetime import datetime

import click
from flask import current_app
from flask.cli import with_appcontext
from sqlalchemy import delete, func, or_, select
from sqlalchemy.orm import Session

from app.care import CareService
from app.config.values import saudi_mobile
from app.database import transaction
from app.extensions import get_clock
from app.models import (
    Account,
    CareCircle,
    CareCircleInvitation,
    CareCircleManager,
    CareCircleRequest,
    OtpRequest,
)


@dataclass(frozen=True)
class KeepPlan:
    """The kept numbers and what goes."""

    keep: frozenset[str]
    kept: list[Account]
    missing: list[str]
    accounts: list[Account]
    circles: list[CareCircle]
    invitations: int
    requests: int
    sign_ins: int

    @property
    def numbers(self) -> tuple[str, ...]:
        """The kept numbers, for a query."""
        return tuple(sorted(self.keep))


def keep_plan(session: Session, keep: Collection[str]) -> KeepPlan:
    """Find what goes when only the accounts of `keep` stay."""
    keep = frozenset(keep)
    numbers = tuple(sorted(keep))
    everyone = session.scalars(
        select(Account).order_by(Account.phone_number)
    ).all()
    kept = [person for person in everyone if person.phone_number in keep]
    others = [p for p in everyone if p.phone_number not in keep]
    other_ids = [person.id for person in others]
    circles = session.scalars(
        select(CareCircle)
        .where(
            or_(
                CareCircle.account_id.in_(other_ids),
                CareCircle.id.in_(
                    select(CareCircleManager.care_circle_id).where(
                        CareCircleManager.account_id.in_(other_ids)
                    )
                ),
            )
        )
        .order_by(CareCircle.first_name, CareCircle.id)
    ).all()
    found = {person.phone_number for person in kept}
    return KeepPlan(
        keep=keep,
        kept=kept,
        missing=sorted(keep - found),
        accounts=others,
        circles=list(circles),
        invitations=_count(
            session,
            CareCircleInvitation,
            CareCircleInvitation.invitee_phone_number.not_in(numbers),
        ),
        requests=_count(
            session,
            CareCircleRequest,
            or_(
                CareCircleRequest.patient_phone_number.not_in(numbers),
                CareCircleRequest.requested_by_account_id.in_(other_ids),
            ),
        ),
        sign_ins=_count(
            session, OtpRequest, OtpRequest.phone_number.not_in(numbers)
        ),
    )


def _count(session: Session, model, condition) -> int:
    """How many rows of `model` meet `condition`."""
    return session.scalar(
        select(func.count()).select_from(model).where(condition)
    )


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


def apply_keep_plan(session: Session, plan: KeepPlan, now: datetime) -> None:
    """Delete what `plan` found; the kept accounts and their own circles
    stay as they are.

    The circles go first, whole, as the demo reset does: deleting a person
    first would change the doses they recorded, and the database refuses a
    changed dose whose medicine is gone when the transaction ends
    (app/demo_data/__init__.py). No circle of a kept account is touched,
    so no kept dose loses its medicine.
    """
    for circle in plan.circles:
        session.delete(circle)
    session.flush()
    other_ids = [person.id for person in plan.accounts]
    session.execute(
        delete(CareCircleInvitation).where(
            CareCircleInvitation.invitee_phone_number.not_in(plan.numbers)
        )
    )
    session.execute(
        delete(CareCircleRequest).where(
            or_(
                CareCircleRequest.patient_phone_number.not_in(plan.numbers),
                CareCircleRequest.requested_by_account_id.in_(other_ids),
            )
        )
    )
    # Each person as the app deletes an account. Their circles are gone
    # already, so nothing more is asked of them here.
    care = CareService(session, now)
    for person in plan.accounts:
        care.delete_account(
            person.id,
            patient_choice="delete",
            delete_last_managed_circles=True,
        )
    session.execute(
        delete(OtpRequest).where(OtpRequest.phone_number.not_in(plan.numbers))
    )
    session.flush()


@click.command("keep-only")
@click.argument("numbers", nargs=-1, required=True)
@click.option(
    "--yes",
    is_flag=True,
    help="Delete. Without it, nothing is deleted: only what would be.",
)
@with_appcontext
def keep_only_command(numbers: tuple[str, ...], yes: bool) -> None:
    """Keep only the accounts of NUMBERS (5XXXXXXXX or +9665XXXXXXXX,
    spaces or commas between them); delete every other account, every
    circle that has one of them, and what waits for their numbers."""
    if current_app.config["APP_ENV"] == "production":
        raise click.ClickException("keep-only never runs in production.")
    keep = _numbers(numbers)
    with transaction() as session:
        plan = keep_plan(session, keep)
        for line in plan_lines(plan):
            click.echo(line)
        if not plan.kept:
            # Most likely the wrong database, or the numbers mistyped.
            raise click.ClickException(
                "None of these numbers has an account here: nothing is "
                "deleted."
            )
        if not yes:
            click.echo("Nothing was deleted. Run it again with --yes.")
            return
        apply_keep_plan(session, plan, get_clock().now())
    click.echo(
        f"Done: {len(plan.accounts)} accounts and {len(plan.circles)} "
        "circles deleted."
    )


def _numbers(numbers: tuple[str, ...]) -> set[str]:
    """Every number given, as +9665XXXXXXXX; a wrong one stops it all."""
    keep: set[str] = set()
    for given in numbers:
        for part in given.split(","):
            if not part.strip():
                continue
            phone = saudi_mobile(part)
            if phone is None:
                raise click.BadParameter(
                    f"{part.strip()!r} is not a Saudi mobile number."
                )
            keep.add(phone)
    return keep
