"""The account page and account deletion on PostgreSQL."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account, CareCircle, Patient
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
        "patient_circle_id": None,
    }


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
        assert session.scalar(select(Patient)).account_id is None


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
        {"display_name": "Nora", "is_you": True, "role": "manager"}
    ]
