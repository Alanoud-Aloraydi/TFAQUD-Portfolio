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

Not for production: it refuses to run there. The demo numbers are made up,
so a real SMS to them could reach a stranger: it runs only with the fake SMS
sender (a demo account signs in with the code it writes in the server log),
or with DEMO_SIGN_IN_CODE set (the demo accounts sign in with that code and
get no SMS; app/sms/demo.py), as on the shared test server on Render, where
/internal/demo-data makes it fresh each morning.
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

from app.appointments.inputs import AppointmentRequest
from app.appointments.service import AppointmentService
from app.care import CareService
from app.circles.inputs import MedicalProfileInput
from app.database import transaction
from app.demo_accounts import DEMO_ACCOUNTS, DEMO_PHONES
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
from app.measurements.inputs import PlanRequest as MeasurementPlanRequest
from app.measurements.inputs import ReadingRequest
from app.measurements.service import MeasurementService
from app.models import Account, CareCircle, CareCircleManager, MedicationPlan

RIYADH = ZoneInfo("Asia/Riyadh")
EVERY_DAY = [1, 2, 3, 4, 5, 6, 7]

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
            recorded_at = min(
                max(taken_at, due) + timedelta(minutes=3), self.now
            )
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

    # ---- today's tasks ----------------------------------------------------

    def clock_in(self, minutes: int) -> str:
        """The «HH:MM» time `minutes` from now, on a five-minute mark and
        kept within today, so a task falls where the story wants it: done,
        late, next or later."""
        moment = self.now + timedelta(minutes=minutes)
        start = datetime.combine(self.today, time(0, 5), tzinfo=RIYADH)
        end = datetime.combine(self.today, time(23, 55), tzinfo=RIYADH)
        moment = min(max(moment, start), end)
        return f"{moment.hour:02d}:{moment.minute - moment.minute % 5:02d}"

    def measure(self, actor, circle, body) -> None:
        MeasurementService(self.session, self.now).create(
            circle.id, actor.id, MeasurementPlanRequest.model_validate(body)
        )

    def appointment(self, actor, circle, body) -> None:
        AppointmentService(self.session, self.now).create(
            circle.id, actor.id, AppointmentRequest.model_validate(body)
        )

    def uncle(self, lina, sara, khaled) -> CareCircle:
        """5. Lina's uncle Khaled, the patient of his own circle in the
        simplified mode, cared for by Lina and Sara. His day has a dose of
        each status (done, late, next, later), a weekly, a monthly and an
        every-other-day medicine, two measurements with their targets, and
        three appointments: one Lina goes to, one only Sara goes to (Lina's
        phone is not reminded of it), and one both go to.
        """
        care = CareService(self.session, self.at(-10))
        request = care.request_creation(
            lina.id, khaled.phone_number, None, "simplified"
        )
        care.respond_creation(khaled.id, request.id, True)
        circle = care.complete_creation(
            khaled.id,
            request.id,
            khaled.birth_date,
            khaled.city,
            *RIYADH_POINT,
            name="صحتي",
        )
        invitation = care.invite_manager(
            lina.id, circle.id, sara.phone_number
        )
        care.respond_invitation(sara.id, invitation.id, True)
        self.medical(
            lina,
            circle,
            {
                "blood_type": "B+",
                "conditions": {
                    "status": "listed",
                    "codes": ["hypertension", "diabetes"],
                },
                "allergies": {
                    "status": "listed",
                    "medication": [],
                    "food": ["nuts"],
                },
            },
        )
        MedicalService(self.session, self.at(-10)).add_contact(
            lina.id, circle.id, "فهد العتيبي", "son", "+966500000021"
        )

        week = self.day(-7)
        medicines = (
            # Taken this morning.
            (
                "أملوديبين", "5", "mg",
                _schedule(self.clock_in(-240), "1", "tablet"),
                "الضغط",
            ),
            # Its time passed and nobody recorded it: late.
            (
                "ميتفورمين", "500", "mg",
                _schedule(
                    self.clock_in(-40), "1", "tablet",
                    instructions="مع الأكل",
                ),
                "السكر",
            ),
            # The next one.
            (
                "أتورفاستاتين", "20", "mg",
                _schedule(
                    self.clock_in(45), "1", "tablet",
                    instructions="بعد العشاء",
                ),
                "الكوليسترول",
            ),
            # Once a month, on today's date: later today.
            (
                "فيتامين ب12", "1000", "mcg",
                {
                    **_schedule("21:00", "1", "tablet"),
                    "repeat": "monthly",
                    "weekdays": [],
                    "month_days": [min(self.today.day, 28)],
                },
                "نقص فيتامين ب12",
            ),
            # Every other day, from a week ago.
            (
                "أسبرين", "81", "mg",
                {
                    **_schedule("08:00", "1", "tablet"),
                    "repeat": "interval",
                    "weekdays": [],
                    "interval_days": 2,
                },
                "حماية القلب",
            ),
        )
        for name, strength, unit, schedule, reason in medicines:
            self.create(
                lina,
                circle,
                _plan(
                    name, strength, unit, "tablet", [schedule], week,
                    reason_for_use=reason,
                ),
                self.at(-8),
            )

        self.measure(lina, circle, {
            "kind": "bp",
            "times": [{"time_of_day": self.clock_in(20), "conditions": []}],
            "weekdays": list(EVERY_DAY),
            "starts_on": self.today,
            "systolic_limit": 140,
            "diastolic_limit": 90,
        })
        self.measure(lina, circle, {
            "kind": "glucose",
            "times": [
                {"time_of_day": "07:00", "conditions": ["fasting"]},
                {
                    "time_of_day": self.clock_in(90),
                    "conditions": ["after_meal"],
                },
            ],
            "weekdays": list(EVERY_DAY),
            "starts_on": self.today,
            "glucose_low": 70,
            "glucose_high": 180,
        })
        # A reading Khaled took himself an hour ago, outside the plan.
        MeasurementService(self.session, self.now).record(
            circle.id,
            khaled.id,
            ReadingRequest.model_validate({
                "kind": "glucose",
                "outcome": "read",
                "measured_at": self.now - timedelta(hours=1),
                "value_one": 135,
                "conditions": ["after_meal"],
            }),
        )

        visits = (
            (
                0, self.clock_in(180), "القلب", "follow_up",
                "مستشفى الملك فيصل التخصصي", [lina.id],
            ),
            (1, "10:00", "تحاليل السكر", "test", "مختبر البرج", [sara.id]),
            (5, "11:30", "العيون", "remote", None, [lina.id, sara.id]),
        )
        for day, clock, specialty, kind, place, going in visits:
            self.appointment(lina, circle, {
                "specialty": specialty,
                "kind": kind,
                "scheduled_on": self.day(day),
                "time_of_day": clock,
                "place": place,
                "remote_method": "video" if kind == "remote" else None,
                "companion_account_ids": going,
            })
        return circle

    def mother_checks(self, lina, mother) -> None:
        """The detailed mode's measurement and appointment: Noura's blood
        pressure twice a day, and a visit Lina takes her to."""
        self.measure(lina, mother, {
            "kind": "bp",
            "times": [
                {"time_of_day": "08:00", "conditions": []},
                {"time_of_day": "20:00", "conditions": []},
            ],
            "weekdays": list(EVERY_DAY),
            "starts_on": self.today,
            "systolic_limit": 140,
            "diastolic_limit": 90,
        })
        self.appointment(lina, mother, {
            "specialty": "الغدد الصماء",
            "kind": "follow_up",
            "scheduled_on": self.day(2),
            "time_of_day": "16:30",
            "place": "مستشفى الملك فهد",
            "companion_account_ids": [lina.id],
        })

    # ---- the story --------------------------------------------------------

    def build(self) -> Summary:
        lina, sara, khaled = self.accounts()
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
                [
                    _schedule(
                        "07:00", "1", "capsule", instructions="قبل الإفطار"
                    )
                ],
                self.day(-14),
                reason_for_use="حموضة المعدة",
            ),
            self.at(-15),
        )

        # 2. Lina's mother, who has no account: every kind of medicine.
        mother = care.create_without_account(
            lina.id,
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
                [
                    _schedule(
                        "14:00", "1", "capsule", instructions="بعد الغداء"
                    )
                ],
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
        recent_care = CareService(self.session, self.at(-5))
        grandfather = recent_care.create_without_account(
            sara.id,
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
            lina.id, REQUEST_PHONE, None, "simplified"
        )

        # The stop and the coming change first, so the dose history follows
        # them: the stopped medicine has no doses after it stopped.
        MedicationPlanService(self.session, self.at(-3, 15)).discontinue(
            mother.id, aspirin.id, lina.id
        )
        plan, later = revise_metformin
        self.revise(lina, mother, plan, 1, later, self.day(5), self.now)

        self.mother_checks(lina, mother)
        uncle = self.uncle(lina, sara, khaled)

        # The doses of the past month.
        self.history(lina, own)
        self.history(lina, mother)
        self.history(sara, grandfather)
        self.history(lina, uncle)

        self.summary.circles = [
            "رعايتي",
            "دائرة نورة",
            "دائرة عبدالله",
            "دائرة خالد",
        ]
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


def demo_allowed(config) -> bool:
    """Whether the demo accounts can be made here: never in production,
    and only where no real SMS can reach their made-up numbers."""
    return config["APP_ENV"] != "production" and (
        config.get("SMS_BACKEND") == "fake"
        or config.get("DEMO_SIGN_IN_CODE") is not None
    )


def rebuild_demo(now: datetime, *, reset: bool) -> tuple[bool, Summary]:
    """Make the demo story at `now`; with `reset`, delete it first.

    Returns whether an old one was deleted, and what was made. Raises
    LookupError when it is already there and `reset` is not set.
    """
    now = now.astimezone(RIYADH)
    with transaction() as session:
        exists = session.scalar(
            select(Account.id).where(Account.phone_number.in_(DEMO_PHONES))
        )
        if exists and not reset:
            raise LookupError("The demo data is already there.")
        removed = remove_demo_accounts(session, now) > 0 if reset else False
        summary = DemoBuilder(session, now).build()
    return removed, summary


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
        raise click.ClickException("Demo data is never made in production.")
    if not demo_allowed(config):
        if if_missing:
            # The server's start (DEMO_DATA=true) must not stop because real
            # SMS was switched on: it only leaves the demo data out.
            click.echo(
                "The demo data is skipped: real SMS is on, the demo numbers "
                "are made up, and DEMO_SIGN_IN_CODE is not set."
            )
            return
        raise click.ClickException(
            "The demo numbers are made up, so they must not get a real SMS. "
            "Set SMS_BACKEND=fake, or DEMO_SIGN_IN_CODE, restart the server, "
            "and run this again."
        )
    try:
        removed, summary = rebuild_demo(get_clock().now(), reset=reset)
    except LookupError:
        if if_missing:
            click.echo("The demo data is already there.")
            return
        raise click.ClickException(
            "The demo data is already there. Run with --reset to make it "
            "fresh."
        ) from None
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
        "Sign in on the phone with 0500000001 (detailed mode) or "
        "0500000004 (simplified mode). The code is DEMO_SIGN_IN_CODE when "
        "it is set, else in the server log (FAKE SMS ... Your code is ...)."
    )
