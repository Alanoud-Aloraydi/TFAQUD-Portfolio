"""The demo data command fills the database through the app's own rules."""

from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.demo_data import DEMO_PHONES, INVITED_PHONE, REQUEST_PHONE
from app.models import (
    Account,
    CareCircle,
    CareCircleCreationRequest,
    CareCircleManagerInvitation,
    MedicationDoseRecord,
    MedicationPlan,
    MedicationPlanVersion,
)


RIYADH = ZoneInfo("Asia/Riyadh")


def _count(engine, model):
    with Session(engine) as session:
        return session.scalar(select(func.count()).select_from(model))


def _run(app, *args):
    return app.test_cli_runner().invoke(args=["demo-data", *args])


def _sign_in(app, client, phone):
    verification = client.post(
        "/api/v1/auth/request-code", json={"phone_number": phone}
    ).get_json()["verification_id"]
    code = app.extensions["sms_sender"].last_message_to(phone).code
    token = client.post(
        "/api/v1/auth/verify-code",
        json={"verification_id": verification, "code": code},
    ).get_json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_demo_data_makes_the_whole_story(database_app, database):
    result = _run(database_app)

    assert result.exit_code == 0, result.output
    assert "Demo data is ready." in result.output
    assert _count(database, Account) == 2
    assert _count(database, CareCircle) == 3
    assert _count(database, MedicationPlan) == 12
    # Two medicines have a second version: one past change, one coming.
    assert _count(database, MedicationPlanVersion) == 14
    assert _count(database, MedicationDoseRecord) > 100
    # Sara invites Lina; Lina invites her sister's number.
    assert _count(database, CareCircleManagerInvitation) == 2
    assert _count(database, CareCircleCreationRequest) == 1


def test_the_demo_account_reads_it_like_the_app(database_app, database):
    _run(database_app)
    client = database_app.test_client()
    headers = _sign_in(database_app, client, DEMO_PHONES[0])

    circles = client.get("/api/v1/home", headers=headers).get_json()[
        "care_circles"
    ]
    assert {circle["name"] for circle in circles} == {"رعايتي", "دائرة نورة"}
    mother = next(c["id"] for c in circles if c["name"] == "دائرة نورة")
    plans = client.get(
        f"/api/v1/circles/{mother}/medication-plans", headers=headers
    ).get_json()["medication_plans"]
    by_name = {plan["version"]["name"]: plan for plan in plans}
    assert by_name["أسبرين"]["discontinued_at"] is not None
    assert by_name["أملوديبين"]["version"]["version_number"] == 2
    assert "pending_version" in by_name["ميتفورمين"]
    assert by_name["ميتفورمين"]["version"]["strength_value"] == "500"
    assert by_name["أوميغا 3"]["version"]["strength_value"] == "1000"

    circle = client.get(f"/api/v1/circles/{mother}", headers=headers).get_json()[
        "circle"
    ]
    [waiting] = circle["pending_invitations"]
    assert waiting["invitee_phone_number"] == INVITED_PHONE
    sent = datetime.fromisoformat(waiting["created_at"])
    assert timedelta(days=1) < datetime.now(UTC) - sent < timedelta(days=3)
    assert [m["is_patient"] for m in circle["members"]] == [False]

    invitations = client.get("/api/v1/invitations", headers=headers).get_json()[
        "invitations"
    ]
    assert [item["circle_name"] for item in invitations] == ["دائرة عبدالله"]
    sent = client.get("/api/v1/circle-requests", headers=headers).get_json()[
        "sent"
    ]
    assert [item["patient_phone_number"] for item in sent] == [REQUEST_PHONE]


def test_it_runs_once_and_resets_on_request(database_app, database):
    assert _run(database_app).exit_code == 0

    again = _run(database_app)
    assert again.exit_code != 0
    assert "--reset" in again.output

    reset = _run(database_app, "--reset")
    assert reset.exit_code == 0, reset.output
    assert "The old demo data was deleted." in reset.output
    assert _count(database, Account) == 2
    assert _count(database, CareCircle) == 3


def test_if_missing_makes_it_once_then_nothing(database_app, database):
    # The server's start on Render (DEMO_DATA=true) runs this at every start.
    first = _run(database_app, "--if-missing")
    assert first.exit_code == 0, first.output
    assert "Demo data is ready." in first.output

    again = _run(database_app, "--if-missing")
    assert again.exit_code == 0, again.output
    assert "The demo data is already there." in again.output
    assert _count(database, Account) == 2
    assert _count(database, CareCircle) == 3


def test_a_reset_works_after_lina_joined_saras_circle(database_app, database):
    # On the phone, Lina accepts Sara's invitation, so «دائرة عبدالله» has two
    # demo managers. A reset deleted one account first and then failed at
    # the end on the doses of that circle; it must delete it whole.
    _run(database_app)
    client = database_app.test_client()
    headers = _sign_in(database_app, client, DEMO_PHONES[0])
    [invitation] = client.get("/api/v1/invitations", headers=headers).get_json()[
        "invitations"
    ]
    accepted = client.post(
        f"/api/v1/invitations/{invitation['id']}/respond",
        json={"accept": True},
        headers=headers,
    )
    assert accepted.status_code == 200, accepted.get_json()
    grandfather = accepted.get_json()["invitation"]["care_circle_id"]
    # Lina also records a dose there, so the failing order happens whichever
    # account goes first: a medicine from today at 00:00, skipped.
    today = datetime.now(RIYADH).date().isoformat()
    created = client.post(
        f"/api/v1/circles/{grandfather}/medication-plans",
        json={
            "name": "باراسيتامول",
            "strength_value": "500",
            "strength_unit": "mg",
            "dosage_form": "tablet",
            "treatment_starts_on": today,
            "treatment_ends_on": None,
            "schedules": [
                {
                    "time_of_day": "00:00",
                    "dose_value": "1",
                    "dose_unit": "tablet",
                    "weekdays": [1, 2, 3, 4, 5, 6, 7],
                    "instructions": None,
                }
            ],
        },
        headers=headers,
    )
    assert created.status_code == 201, created.get_json()
    [schedule] = created.get_json()["medication_plan"]["version"]["schedules"]
    recorded = client.put(
        f"/api/v1/circles/{grandfather}/medication-dose-records/"
        f"{schedule['id']}/{today}",
        json={
            "outcome": "skipped",
            "skip_reason_code": "other",
            "skip_reason_note": "تجربة",
        },
        headers=headers,
    )
    assert recorded.status_code == 200, recorded.get_json()

    reset = _run(database_app, "--reset")

    assert reset.exit_code == 0, reset.output
    assert _count(database, Account) == 2
    assert _count(database, CareCircle) == 3
    assert _count(database, CareCircleManagerInvitation) == 2


def test_a_reset_leaves_other_accounts_alone(database_app, database):
    with Session(database, expire_on_commit=False) as session:
        with session.begin():
            other = Account(
                phone_number="+966511111111",
                first_name="هدى",
                last_name="الشمري",
                display_name="هدى",
            )
            session.add(other)
    _run(database_app)

    assert _run(database_app, "--reset").exit_code == 0
    with Session(database) as session:
        assert session.get(Account, other.id) is not None
    assert _count(database, Account) == 3


def test_it_needs_the_fake_sms(database_app, database):
    database_app.config["SMS_BACKEND"] = "authentica"
    try:
        result = _run(database_app)
    finally:
        database_app.config["SMS_BACKEND"] = "fake"

    assert result.exit_code != 0
    assert "SMS_BACKEND=fake" in result.output
    assert _count(database, Account) == 0


def test_the_start_skips_it_with_real_sms(database_app, database):
    # On Render, DEMO_DATA=true runs --if-missing at every start: with real
    # SMS it must say so and let the server start, making nothing.
    database_app.config["SMS_BACKEND"] = "authentica"
    try:
        result = _run(database_app, "--if-missing")
    finally:
        database_app.config["SMS_BACKEND"] = "fake"

    assert result.exit_code == 0, result.output
    assert "skipped" in result.output
    assert _count(database, Account) == 0
