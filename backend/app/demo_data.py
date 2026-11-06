"""Demo data for trying the app against a local server.

    flask --app wsgi demo-data            make the demo data
    flask --app wsgi demo-data --reset    delete it and make it fresh
    flask --app wsgi demo-data --if-missing   make it only when it is not
                                              there (the server's start on
                                              Render, with DEMO_DATA=true)

It makes two demo accounts and fills the first one with care circles,
medicines of every kind and a month of dose records. Everything goes through
the app's own services (care, medical file, medication plans, dose records),
with the clock set back where the story needs it, so every row is one the
app could have made itself and the database rules check all of it.

Not for production: it refuses to run there, and it refuses unless the
fake SMS sender is on: the demo numbers are made up, so a real SMS to them
could reach a stranger. A demo account signs in with the code that the fake
sender writes in the server log.
"""

import random
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

import click
from flask import current_app
from flask.cli import with_appcontext
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.care import CareService
from app.circles.inputs import MedicalProfileInput
from app.database import transaction
from app.extensions import get_clock
from app.medical import MedicalService
from app.medications.doses import MedicationDoseService
from app.medications.inputs import (
    DoseRecordRequest,
    PlanRequest,
    RevisePlanRequest,
)
from app.medications.plans import MedicationPlanService
from app.medications.queries import MedicationQueries
from app.models import Account, CareCircle, CareCircleManager, MedicationPlan

RIYADH = ZoneInfo("Asia/Riyadh")
EVERY_DAY = [1, 2, 3, 4, 5, 6, 7]

# (phone, first name, last name, display name). The first one is the
# account to sign in with; the second invites it to her circle.
# Phone, names, and the birth date and city that onboarding asks for.
DEMO_ACCOUNTS = (
    ("+966500000001", "لينا", "العتيبي", "لينا", date(1994, 3, 12), "الرياض"),
    ("+966500000002", "سارة", "القحطاني", "سارة", date(1990, 9, 2), "جدة"),
)
DEMO_PHONES = tuple(phone for phone, *_ in DEMO_ACCOUNTS)
# A number with no account: the main demo account asks it for a circle.
REQUEST_PHONE = "+966500000003"
# A number with no account: the main demo account invites it to help with
# her mother's care, and the invitation waits.
INVITED_PHONE = "+966559876543"

RIYADH_POINT = (24.7136, 46.6753)
JEDDAH_POINT = (21.4858, 39.1925)

# How far back the dose records go.
HISTORY_DAYS = 30
# Today's doses due in this window before now are left without a record,
# so the app shows them as due, late or missed.
OPEN_WINDOW = timedelta(hours=3)

SKIP_REASONS = (
    "forgotten",
    "unavailable",
    "side_effects",
    "patient_refused",
    "other",
)


@dataclass
class Summary:
    """What was made, for the message at the end."""

    circles: list[str] = field(default_factory=list)
    plans: int = 0
    revisions: int = 0
    taken: int = 0
    skipped: int = 0
    open_doses: int = 0


def _schedule(clock, dose, unit, days=EVERY_DAY, instructions=None):
    return {
        "time_of_day": clock,
        "dose_value": dose,
        "dose_unit": unit,
        "weekdays": list(days),
        "instructions": instructions,
    }


def _plan(name, strength, unit, form, schedules, starts, ends=None, **more):
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


class DemoBuilder:
    """Make the demo story in one session, at `now` (Asia/Riyadh)."""

    def __init__(self, session: Session, now: datetime):
        self.session = session
        self.now = now.astimezone(RIYADH)
        self.today = self.now.date()
        self.summary = Summary()

    # ---- time -------------------------------------------------------------

    def day(self, offset: int) -> date:
        return self.today + timedelta(days=offset)

    def at(self, offset: int, hour: int = 9, minute: int = 0) -> datetime:
        return datetime.combine(
            self.day(offset), time(hour, minute), tzinfo=RIYADH
        )

    # ---- people and circles ---------------------------------------------

    def accounts(self) -> list[Account]:
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
        MedicalService(self.session, self.at(-60)).update_profile(
            actor.id,
            circle.id,
            MedicalProfileInput.model_validate(profile).to_update(),
        )

    # ---- medicines --------------------------------------------------------

    def create(self, actor, circle, body, when) -> MedicationPlan:
        plan = MedicationPlanService(self.session, when).create(
            circle.id, actor.id, PlanRequest.model_validate(body)
        )
        self.summary.plans += 1
        return plan

    def revise(self, actor, circle, plan, version, body, effective, when):
        MedicationPlanService(self.session, when).revise(
            circle.id,
            plan.id,
            actor.id,
            RevisePlanRequest.model_validate(
                {
                    **body,
                    "expected_version_number": version,
                    "effective_from_on": effective,
                }
            ),
        )
        self.summary.revisions += 1

    # ---- dose records -----------------------------------------------------

    def history(self, actor: Account, circle: CareCircle) -> None:
        """Record the past doses of a circle, as a family would have.

        About 8 in 10 doses are taken (some late), about 1 in 10 skipped with
        a reason, and the rest have no record (missed). Today's doses due in
        the last 3 hours stay open, and later ones are still to come.
        The choice per dose is fixed by the dose itself, so a reset gives
        the same picture.
        """
        queries = MedicationQueries(self.session, self.now)
        start = self.day(-HISTORY_DAYS)
        while start <= self.today:
            end = min(start + timedelta(days=30), self.today)
            for item in queries.occurrences(circle.id, start, end):
                self._record(actor, circle, item)
            start = end + timedelta(days=1)

    def _record(self, actor: Account, circle: CareCircle, item: dict):
        if item.get("record") is not None:
            return
        scheduled_on = date.fromisoformat(item["scheduled_on"])
        due = datetime.combine(
            scheduled_on,
            time.fromisoformat(item["time_of_day"]),
            tzinfo=RIYADH,
        )
        if due > self.now:
            return
        if due > self.now - OPEN_WINDOW:
            self.summary.open_doses += 1
            return
        chance = random.Random(
            f"{item['name']}|{item['scheduled_on']}|{item['time_of_day']}"
        )
        roll = chance.random()
        today = scheduled_on == self.today
        if today or roll < 0.80:
            taken_at = due + timedelta(minutes=chance.randint(-10, 45))
            recorded_at = min(max(taken_at, due) + timedelta(minutes=3), self.now)
            body = {"outcome": "taken", "taken_at": min(taken_at, recorded_at)}
            self.summary.taken += 1
        elif roll < 0.92:
            reason = chance.choice(SKIP_REASONS)
            recorded_at = min(due + timedelta(minutes=45), self.now)
            body = {"outcome": "skipped", "skip_reason_code": reason}
            if reason == "other":
                body["skip_reason_note"] = "كانت نائمة وقت الجرعة"
            self.summary.skipped += 1
        else:
            return
        MedicationDoseService(self.session, recorded_at).record(
            circle.id,
            UUID(item["schedule_id"]),
            scheduled_on,
            actor.id,
            DoseRecordRequest.model_validate(body),
        )

    # ---- the story --------------------------------------------------------

    def build(self) -> Summary:
        lina, sara = self.accounts()
        care = CareService(self.session, self.at(-60))

        # 1. Lina's own care: two simple medicines.
        own = care.create_self(
            lina.id, "رعايتي", date(1995, 4, 12), "الرياض", *RIYADH_POINT
        )
        self.medical(
            lina,
            own,
            {
                "blood_type": "O+",
                "conditions": {"status": "none"},
                "allergies": {"status": "none"},
            },
        )
        self.create(
            lina,
            own,
            _plan(
                "فيتامين د",
                "25",
                "mcg",
                "capsule",
                [_schedule("09:00", "1", "capsule")],
                self.day(-20),
                reason_for_use="نقص فيتامين د",
            ),
            self.at(-21),
        )
        self.create(
            lina,
            own,
            _plan(
                "أوميبرازول",
                "20",
                "mg",
                "capsule",
                [_schedule("07:00", "1", "capsule", instructions="قبل الإفطار")],
                self.day(-14),
                reason_for_use="حموضة المعدة",
            ),
            self.at(-15),
        )

        # 2. Lina's mother, who has no account: every kind of medicine.
        mother = care.create_without_account(
            lina.id,
            "رعاية أمي",
            "نورة",
            "العتيبي",
            date(1956, 8, 3),
            "الرياض",
            *RIYADH_POINT,
        )
        self.medical(
            lina,
            mother,
            {
                "blood_type": "A+",
                "conditions": {
                    "status": "listed",
                    "codes": ["diabetes", "hypertension"],
                },
                "allergies": {
                    "status": "listed",
                    "medication": ["penicillin"],
                    "food": [],
                },
            },
        )
        contacts = MedicalService(self.session, self.at(-60))
        contacts.add_contact(
            lina.id, mother.id, "محمد العتيبي", "son", "+966500000011"
        )
        contacts.add_contact(
            lina.id, mother.id, "ريم العتيبي", "daughter", "+966500000012"
        )

        # Twice a day, with a change that starts in 5 days (a pending
        # revision): the evening dose becomes 2 tablets.
        metformin = _plan(
            "ميتفورمين",
            "500",
            "mg",
            "tablet",
            [
                _schedule("08:00", "1", "tablet", instructions="مع الإفطار"),
                _schedule("20:00", "1", "tablet", instructions="مع العشاء"),
            ],
            self.day(-45),
            reason_for_use="السكري",
        )
        plan = self.create(lina, mother, metformin, self.at(-46))
        later = dict(metformin)
        later["schedules"] = [
            _schedule("08:00", "1", "tablet", instructions="مع الإفطار"),
            _schedule("20:00", "2", "tablet", instructions="مع العشاء"),
        ]
        revise_metformin = (plan, later)

        # Revised 10 days ago: half a tablet became one tablet.
        amlodipine = _plan(
            "أملوديبين",
            "5",
            "mg",
            "tablet",
            [_schedule("09:00", "0.5", "tablet")],
            self.day(-40),
            reason_for_use="ضغط الدم",
        )
        plan = self.create(lina, mother, amlodipine, self.at(-41))
        self.revise(
            lina,
            mother,
            plan,
            1,
            {**amlodipine, "schedules": [_schedule("09:00", "1", "tablet")]},
            self.day(-10),
            self.at(-11),
        )

        # An injection, in units.
        self.create(
            lina,
            mother,
            _plan(
                "إنسولين لانتوس",
                "100",
                "unit/mL",
                "injection",
                [_schedule("22:00", "12", "unit", instructions="تحت الجلد")],
                self.day(-30),
                reason_for_use="السكري",
                missed_after_minutes=120,
            ),
            self.at(-31),
        )

        # A short course of syrup that ends in 4 days.
        self.create(
            lina,
            mother,
            _plan(
                "شراب الكحة",
                "15",
                "mg/5mL",
                "liquid",
                [
                    _schedule("13:00", "5", "mL"),
                    _schedule("21:00", "5", "mL"),
                ],
                self.day(-3),
                self.day(4),
                reason_for_use="الكحة",
                missed_after_minutes=30,
            ),
            self.at(-4),
        )

        # Drops on three days of the week only (Sunday, Tuesday, Thursday).
        self.create(
            lina,
            mother,
            _plan(
                "قطرة العين",
                "0.5",
                "%",
                "drops",
                [_schedule("10:00", "2", "drop", days=[7, 2, 4])],
                self.day(-25),
                reason_for_use="جفاف العين",
            ),
            self.at(-26),
        )

        # An inhaler on Monday, Wednesday and Friday evenings.
        self.create(
            lina,
            mother,
            _plan(
                "فنتولين",
                "100",
                "mcg/dose",
                "inhaler",
                [_schedule("18:00", "2", "puff", days=[1, 3, 5])],
                self.day(-18),
                reason_for_use="ضيق التنفس",
            ),
            self.at(-19),
        )

        # Scheduled: starts in a week.
        self.create(
            lina,
            mother,
            _plan(
                "أوميغا 3",
                "1000",
                "mg",
                "capsule",
                [_schedule("14:00", "1", "capsule", instructions="بعد الغداء")],
                self.day(7),
            ),
            self.at(0, 8),
        )

        # Previous: a finished one-week course.
        self.create(
            lina,
            mother,
            _plan(
                "سيبروفلوكساسين",
                "500",
                "mg",
                "tablet",
                [
                    _schedule("08:00", "1", "tablet"),
                    _schedule("20:00", "1", "tablet"),
                ],
                self.day(-28),
                self.day(-22),
                reason_for_use="التهاب المسالك",
            ),
            self.at(-29),
        )

        # Stopped 3 days ago by the family.
        aspirin = self.create(
            lina,
            mother,
            _plan(
                "أسبرين",
                "81",
                "mg",
                "tablet",
                [_schedule("12:00", "1", "tablet")],
                self.day(-35),
                reason_for_use="سيولة الدم",
            ),
            self.at(-36),
        )

        # 3. Sara's grandfather in Jeddah. Sara invites Lina to manage it,
        # so Lina's bell has an invitation to answer.
        grandfather = CareService(self.session, self.at(-5)).create_without_account(
            sara.id,
            "رعاية جدي",
            "عبدالله",
            "القحطاني",
            date(1948, 1, 20),
            "جدة",
            *JEDDAH_POINT,
        )
        self.create(
            sara,
            grandfather,
            _plan(
                "وارفارين",
                "5",
                "mg",
                "tablet",
                [_schedule("19:00", "1", "tablet")],
                self.day(-5),
                reason_for_use="سيولة الدم",
            ),
            self.at(-5),
        )
        CareService(self.session, self.at(-1)).invite_manager(
            sara.id, grandfather.id, lina.phone_number
        )

        # Lina invited her sister to help with their mother two days ago;
        # the Circle tab shows it as a pending invitation.
        sister = CareService(self.session, self.at(-2)).invite_manager(
            lina.id, mother.id, INVITED_PHONE
        )
        sister.created_at = sister.last_sent_at

        # 4. Lina asked her father's number for a circle; it waits for him.
        CareService(self.session, self.at(-2)).request_creation(
            lina.id, REQUEST_PHONE, "أبي", "simplified"
        )

        # The stop and the coming change first, so the dose history follows
        # them: the stopped medicine has no doses after it stopped.
        MedicationPlanService(self.session, self.at(-3, 15)).discontinue(
            mother.id, aspirin.id, lina.id
        )
        plan, later = revise_metformin
        self.revise(lina, mother, plan, 1, later, self.day(5), self.now)

        # The doses of the past month.
        self.history(lina, own)
        self.history(lina, mother)
        self.history(sara, grandfather)

        self.summary.circles = ["رعايتي", "رعاية أمي", "رعاية جدي"]
        return self.summary


def remove_demo_accounts(session: Session, now: datetime) -> int:
    """Delete the demo accounts as the app deletes an account.

    Each one deletes its own circle and the circles it manages alone, and
    leaves any circle that someone else also manages. Accounts that are
    not demo accounts are never touched.

    The circles that only demo accounts manage are deleted first, whole.
    Otherwise, after Lina accepted Sara's invitation on the phone, deleting
    one account first changes the doses it recorded (their recorder becomes
    empty) and deleting the other then removes those doses with the circle.
    The database checks every changed dose when the transaction ends, finds
    its medicine gone, and refuses the whole reset ("Dose date does not
    belong to this schedule").
    """
    accounts = session.scalars(
        select(Account)
        .where(Account.phone_number.in_(DEMO_PHONES))
        .order_by(Account.phone_number)
    ).all()
    demo_ids = {account.id for account in accounts}
    managed = session.scalars(
        select(CareCircle).where(
            CareCircle.id.in_(
                select(CareCircleManager.care_circle_id).where(
                    CareCircleManager.account_id.in_(demo_ids)
                )
            )
        )
    ).all()
    for circle in managed:
        managers = set(
            session.scalars(
                select(CareCircleManager.account_id).where(
                    CareCircleManager.care_circle_id == circle.id
                )
            )
        )
        if managers <= demo_ids:
            session.delete(circle)
    session.flush()
    care = CareService(session, now)
    for account in accounts:
        care.delete_account(
            account.id,
            patient_choice="delete",
            delete_last_managed_circles=True,
        )
    session.flush()
    return len(accounts)


@click.command("demo-data")
@click.option(
    "--reset",
    is_flag=True,
    help="Delete the demo accounts and their circles first.",
)
@click.option(
    "--if-missing",
    is_flag=True,
    help="Do nothing when the demo data is already there.",
)
@with_appcontext
def demo_data_command(reset: bool, if_missing: bool) -> None:
    """Fill the local database with demo circles, medicines and doses."""
    config = current_app.config
    if config["APP_ENV"] == "production":
        raise click.ClickException("Demo data is for a local server only.")
    if config.get("SMS_BACKEND") != "fake":
        if if_missing:
            # The server's start (DEMO_DATA=true) must not stop because real
            # SMS was switched on: it only leaves the demo data out.
            click.echo(
                "The demo data is skipped: real SMS is on, and the demo "
                "numbers are made up."
            )
            return
        raise click.ClickException(
            "The demo numbers are made up, so they must not get a real SMS. "
            "Set SMS_BACKEND=fake in backend/.env, restart the server, and "
            "run this again."
        )
    now = get_clock().now().astimezone(RIYADH)
    with transaction() as session:
        exists = session.scalar(
            select(Account.id).where(Account.phone_number.in_(DEMO_PHONES))
        )
        if exists and if_missing and not reset:
            click.echo("The demo data is already there.")
            return
        if exists and not reset:
            raise click.ClickException(
                "The demo data is already there. Run with --reset to make "
                "it fresh."
            )
        removed = remove_demo_accounts(session, now) if reset else 0
        summary = DemoBuilder(session, now).build()
    if removed:
        click.echo("The old demo data was deleted.")
    click.echo("Demo data is ready.")
    click.echo(f"  Circles: {', '.join(summary.circles)}")
    click.echo(
        f"  Medicines: {summary.plans} ({summary.revisions} changes)"
    )
    click.echo(
        f"  Doses: {summary.taken} taken, {summary.skipped} skipped, "
        f"{summary.open_doses} due now, the rest missed or to come"
    )
    click.echo(
        "Sign in on the phone with 0500000001. The code is in the server "
        "log (FAKE SMS ... Your code is ...)."
    )
