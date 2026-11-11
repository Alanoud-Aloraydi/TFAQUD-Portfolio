"""The account page and account deletion on PostgreSQL."""

from datetime import datetime, timezone

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.clock import ManualClock
from app.models import Account, CareCircle
from integration_tests.helpers import Api, BIRTH, add_manager, count
from integration_tests.helpers import error_code, offline_circle, run

URL = "/api/v1/accounts/me"


def test_the_account_page_reads_the_real_account(
    database_app, database, account
):
    owner = account(mode="detailed", name="Reem")

    response = Api(database_app, owner).get(URL)

    assert response.status_code == 200
    assert response.json["account"] == {
        "id": owner.id.hex,
        "phone_number": owner.phone_number,
        "first_name": "Reem",
        "last_name": "Family",
        "display_name": "Reem",
        "profile_complete": True,
        "app_mode": "detailed",
        "birth_date": None,
        "city": None,
        "patient_circle_id": None,
        "avatar_code": None,
    }


def test_onboarding_saves_the_birth_date_and_city(
    database_app, database, account
):
    api = Api(database_app, account(name="Reem"))
    names = {
        "first_name": "Reem",
        "last_name": "Family",
        "display_name": "Reem",
    }

    saved = api.put(
        f"{URL}/profile",
        {**names, "birth_date": "1990-03-04", "city": "Riyadh"},
    )
    assert saved.status_code == 200
    assert saved.json["account"]["birth_date"] == "1990-03-04"
    assert saved.json["account"]["city"] == "Riyadh"

    # The account page sends only the names: the birth date and city stay.
    renamed = api.put(f"{URL}/profile", {**names, "display_name": "R"})
    assert renamed.json["account"]["birth_date"] == "1990-03-04"
    assert renamed.json["account"]["city"] == "Riyadh"
    assert api.get(URL).json["account"]["city"] == "Riyadh"


def test_a_birth_date_in_the_future_is_not_saved(
    database_app, database, account
):
    api = Api(database_app, account())

    response = api.put(
        f"{URL}/profile",
        {
            "first_name": "Nora",
            "last_name": "Family",
            "display_name": "Nora",
            "birth_date": "2999-01-01",
            "city": "Riyadh",
        },
    )

    assert error_code(response, 422) == "invalid_birth_date"


def test_deleting_an_account_without_circles_ends_its_sign_in(
    database_app, database, account
):
    api = Api(database_app, account())

    response = api.delete(URL)

    assert response.status_code == 204
    assert count(database, Account) == 0
    assert api.get("/api/v1/home").status_code == 401


def test_a_bad_body_is_refused_before_anything_is_deleted(
    database_app, database, account
):
    api = Api(database_app, account())

    invalid = api.client.delete(URL, data="oops", headers=api.headers)
    unknown = api.delete(URL, {"patient_choice": "maybe"})

    assert error_code(invalid, 400) == "invalid_json"
    assert error_code(unknown, 422) == "validation_error"
    assert count(database, Account) == 1


def test_a_patient_must_choose_what_happens_to_their_circle(
    database_app, database, account
):
    owner, member = account(), account(name="Khaled")
    circle = run(database, "create_self", owner.id, "Care", BIRTH, "Riyadh")
    add_manager(database, owner, circle, member)
    api = Api(database_app, owner)

    refused = api.delete(URL)

    assert error_code(refused, 422) == "patient_choice_required"
    assert count(database, Account) == 2


def test_continued_care_keeps_the_circle_and_the_patient_name(
    database_app, database, account
):
    owner, member = account(name="Noura"), account(name="Khaled")
    circle = run(database, "create_self", owner.id, "Care", BIRTH, "Riyadh")
    add_manager(database, owner, circle, member)

    response = Api(database_app, owner).delete(
        URL, {"patient_choice": "continue"}
    )

    assert response.status_code == 204
    view = Api(database_app, member).get(f"/api/v1/circles/{circle.id}")
    patient = view.json["circle"]["patient"]
    assert patient["has_account"] is False
    assert patient["first_name"] == "Noura"
    assert [m["display_name"] for m in view.json["circle"]["members"]] == [
        "Khaled"
    ]
    with Session(database) as session:
        assert session.scalar(select(CareCircle)).account_id is None


def test_a_patient_can_delete_the_circle_with_the_account(
    database_app, database, account
):
    owner, member = account(), account()
    circle = run(database, "create_self", owner.id, "Care", BIRTH, "Riyadh")
    add_manager(database, owner, circle, member)

    response = Api(database_app, owner).delete(
        URL, {"patient_choice": "delete"}
    )

    assert response.status_code == 204
    assert count(database, CareCircle) == 0
    assert count(database, Account) == 1


def test_the_only_manager_must_agree_to_delete_the_circle(
    database_app, database, account
):
    owner = account()
    offline_circle(database, owner)
    api = Api(database_app, owner)

    refused = api.delete(URL)
    assert error_code(refused, 422) == "last_manager"
    assert count(database, CareCircle) == 1
    assert count(database, Account) == 1

    done = api.delete(URL, {"delete_last_managed_circles": True})
    assert done.status_code == 204
    assert count(database, CareCircle) == 0
    assert count(database, Account) == 0


def test_a_member_leaves_other_circles_untouched(
    database_app, database, account
):
    owner, member = account(), account()
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, member)

    response = Api(database_app, member).delete(URL)

    assert response.status_code == 204
    assert count(database, CareCircle) == 1
    assert Api(database_app, owner).get(f"/api/v1/circles/{circle.id}").json[
        "circle"
    ]["members"] == [
        {
            "account_id": str(owner.id),
            "display_name": "Nora",
            "is_you": True,
            "is_patient": False,
            "role": "manager",
            "avatar_code": None,
            "phone_number": owner.phone_number,
        }
    ]


def test_a_companion_who_deletes_their_account_leaves_the_visit_in_place(
    database_app, database, account, monkeypatch
):
    # 9 November 2026 in Riyadh: the visit on the 11th is still to come.
    monkeypatch.setitem(
        database_app.extensions,
        "clock",
        ManualClock(datetime(2026, 11, 8, 22, 9, tzinfo=timezone.utc)),
    )
    owner, member = account(name="لينا"), account(name="حامد")
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, member)
    base = f"/api/v1/circles/{circle.id}/appointments"
    saved = Api(database_app, owner).post(base, {
        "specialty": "السكري",
        "kind": "follow_up",
        "other_text": None,
        "scheduled_on": "2026-11-11",
        "time_of_day": "10:00",
        "place": "الحبيب",
        "remote_method": None,
        "companion_account_ids": [str(member.id)],
    }).get_json()["appointment"]

    deleted = Api(database_app, member).delete(URL)

    assert deleted.status_code == 204, deleted.get_json()
    owner_api = Api(database_app, owner)
    (visit,) = owner_api.get(base).get_json()["appointments"]
    assert (visit["id"], visit["companions"]) == (saved["id"], [])
    # The visit with no companion left can still be closed.
    closed = owner_api.post(f"{base}/{saved['id']}/status", {
        "status": "cancelled",
        "expected_updated_at": visit["updated_at"],
    })
    assert closed.status_code == 200, closed.get_json()


def test_a_dose_is_checked_again_only_when_its_day_or_schedule_changes(
    database,
):
    # Deleting the account that recorded a dose clears its recorder; that
    # must not check the dose against a medicine changed since.
    with Session(database) as session:
        definition = session.scalar(text(
            "SELECT pg_get_triggerdef(oid) FROM pg_trigger "
            "WHERE tgname = 'trg_medication_dose_record_check_valid'"
        ))
    assert "UPDATE OF schedule_id, scheduled_on" in definition
