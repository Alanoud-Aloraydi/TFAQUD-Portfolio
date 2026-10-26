"""Medical profile and emergency contacts on PostgreSQL."""

from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.medical import Conditions, MedicalService, MedicalUpdate
from app.models import PatientCondition
from integration_tests.helpers import Api, NOW, add_manager, count, error_code
from integration_tests.helpers import offline_circle
from integration_tests.test_circle_api import simplified_circle

PHONE = "+966511111111"


def url(circle, tail=""):
    return f"/api/v1/circles/{circle.id}{tail}"


def profile_url(circle):
    return url(circle, "/medical-profile")


@pytest.fixture
def setup(database_app, database, account):
    owner = account()
    circle = offline_circle(database, owner)
    return Api(database_app, owner), circle


# ---- reading and the shape of the answer ---------------------------------


def test_a_new_circle_has_an_unknown_medical_file(setup):
    api, circle = setup

    body = api.get(profile_url(circle)).json

    assert body["medical_profile"] == {
        "blood_type": None,
        "conditions": {"status": "unknown", "codes": [], "other": None},
        "allergies": {
            "status": "unknown",
            "medication": [],
            "other_medication": None,
            "food": [],
            "other_food": None,
        },
    }
    assert body["emergency_contacts"] == []
    assert body["patient"]["first_name"] == "Nora"
    assert body["patient"]["city"] == "Buraidah"


def test_blood_type_conditions_and_allergies_are_saved(setup):
    api, circle = setup

    response = api.patch(
        profile_url(circle),
        {
            "blood_type": "AB-",
            "conditions": {
                "status": "listed",
                "codes": ["thyroid", "diabetes", "other"],
                "other": "Gout",
            },
            "allergies": {
                "status": "listed",
                "medication": ["aspirin_nsaids", "penicillin", "other"],
                "other_medication": "Codeine",
                "food": ["sesame", "milk"],
            },
        },
    )

    assert response.status_code == 200
    saved = api.get(profile_url(circle)).json["medical_profile"]
    assert saved == response.json["medical_profile"]
    assert saved["blood_type"] == "AB-"
    # Codes always come back in the order of the official list.
    assert saved["conditions"] == {
        "status": "listed",
        "codes": ["diabetes", "thyroid", "other"],
        "other": "Gout",
    }
    assert saved["allergies"] == {
        "status": "listed",
        "medication": ["penicillin", "aspirin_nsaids", "other"],
        "other_medication": "Codeine",
        "food": ["milk", "sesame"],
        "other_food": None,
    }


def test_no_conditions_and_no_allergies_are_different_from_unknown(setup):
    api, circle = setup

    api.patch(
        profile_url(circle),
        {
            "conditions": {"status": "none"},
            "allergies": {"status": "none"},
        },
    )

    saved = api.get(profile_url(circle)).json["medical_profile"]
    assert saved["conditions"]["status"] == "none"
    assert saved["allergies"]["status"] == "none"


# ---- changing parts -----------------------------------------------------


def test_only_the_parts_in_the_body_change(setup):
    api, circle = setup
    api.patch(
        profile_url(circle),
        {
            "blood_type": "O+",
            "conditions": {"status": "listed", "codes": ["asthma"]},
        },
    )

    api.patch(profile_url(circle), {"allergies": {"status": "none"}})

    saved = api.get(profile_url(circle)).json["medical_profile"]
    assert saved["blood_type"] == "O+"
    assert saved["conditions"]["codes"] == ["asthma"]
    assert saved["allergies"]["status"] == "none"


def test_null_clears_a_part_back_to_unknown(setup):
    api, circle = setup
    api.patch(
        profile_url(circle),
        {
            "blood_type": "O+",
            "conditions": {"status": "listed", "codes": ["asthma"]},
        },
    )

    api.patch(profile_url(circle), {"blood_type": None, "conditions": None})

    saved = api.get(profile_url(circle)).json["medical_profile"]
    assert saved["blood_type"] is None
    assert saved["conditions"]["status"] == "unknown"


def test_a_new_list_replaces_the_old_one(setup, database):
    api, circle = setup
    api.patch(
        profile_url(circle),
        {"conditions": {"status": "listed", "codes": ["heart", "kidney"]}},
    )

    api.patch(
        profile_url(circle),
        {"conditions": {"status": "listed", "codes": ["kidney", "asthma"]}},
    )

    saved = api.get(profile_url(circle)).json["medical_profile"]
    assert saved["conditions"]["codes"] == ["asthma", "kidney"]
    assert count(database, PatientCondition) == 2


# ---- refusals -----------------------------------------------------------


@pytest.mark.parametrize(
    "body,code",
    [
        (
            {"conditions": {"status": "none", "codes": ["asthma"]}},
            "none_is_exclusive",
        ),
        ({"conditions": {"status": "listed", "codes": []}}, "empty_selection"),
        (
            {"conditions": {"status": "listed", "codes": ["heart", "heart"]}},
            "duplicate_choice",
        ),
        (
            {"conditions": {"status": "listed", "codes": ["other"]}},
            "other_text_required",
        ),
        (
            {
                "conditions": {
                    "status": "listed",
                    "codes": ["other"],
                    "other": "x" * 101,
                }
            },
            "validation_error",
        ),
        (
            {
                "conditions": {
                    "status": "listed",
                    "codes": ["asthma"],
                    "other": "Gout",
                }
            },
            "other_text_unexpected",
        ),
        (
            {"allergies": {"status": "none", "food": ["milk"]}},
            "none_is_exclusive",
        ),
        ({"allergies": {"status": "listed"}}, "empty_selection"),
        (
            {"allergies": {"status": "listed", "food": ["other"]}},
            "other_text_required",
        ),
        (
            {
                "allergies": {
                    "status": "listed",
                    "medication": ["penicillin"],
                    "other_food": "Kiwi",
                }
            },
            "other_text_unexpected",
        ),
        ({"blood_type": "C+"}, "validation_error"),
        (
            {"conditions": {"status": "listed", "codes": ["flu"]}},
            "validation_error",
        ),
        ({"surprise": 1}, "validation_error"),
    ],
)
def test_wrong_medical_data_is_refused_and_nothing_changes(setup, body, code):
    api, circle = setup
    api.patch(profile_url(circle), {"blood_type": "A+"})

    response = api.patch(profile_url(circle), body)

    assert error_code(response, 422) == code
    saved = api.get(profile_url(circle)).json["medical_profile"]
    assert saved["blood_type"] == "A+"
    assert saved["conditions"]["status"] == "unknown"


def test_a_service_error_names_the_field(setup):
    api, circle = setup

    response = api.patch(
        profile_url(circle),
        {"conditions": {"status": "listed", "codes": ["other"]}},
    )

    assert response.json["error"]["details"][0]["field"] == "conditions"


# ---- who may use it -------------------------------------------------------


def test_only_members_of_the_circle_reach_the_medical_file(
    database_app, database, account, setup
):
    api, circle = setup
    stranger = Api(database_app, account())

    for response in (
        stranger.get(profile_url(circle)),
        stranger.patch(profile_url(circle), {"blood_type": "A+"}),
        stranger.post(
            url(circle, "/emergency-contacts"),
            {"name": "Reem", "relation": "son", "phone_number": PHONE},
        ),
    ):
        assert error_code(response, 403) == "forbidden"


def test_the_patient_and_every_manager_can_edit_the_medical_file(
    database_app, database, account
):
    owner, second, patient = account(), account(), account()
    circle = simplified_circle(database, owner, patient)
    add_manager(database, owner, circle, second)

    for who, blood in ((owner, "A+"), (second, "B+"), (patient, "O-")):
        response = Api(database_app, who).patch(
            profile_url(circle), {"blood_type": blood}
        )
        assert response.status_code == 200
        assert response.json["medical_profile"]["blood_type"] == blood


def test_a_manager_who_left_loses_the_medical_file(
    database_app, database, account
):
    owner, member = account(), account()
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, member)
    api = Api(database_app, member)
    assert api.get(profile_url(circle)).status_code == 200

    api.post(url(circle, "/leave"))

    assert error_code(api.get(profile_url(circle)), 403) == "forbidden"


# ---- emergency contacts -----------------------------------------------------


def contact(name="Reem", relation="daughter", phone=PHONE):
    return {"name": name, "relation": relation, "phone_number": phone}


def test_emergency_contacts_are_added_listed_changed_and_removed(setup):
    api, circle = setup

    added = api.post(url(circle, "/emergency-contacts"), contact())
    assert added.status_code == 201
    saved = added.json["emergency_contact"]
    assert saved["name"] == "Reem"
    assert saved["relation"] == "daughter"
    assert saved["phone_number"] == PHONE

    listed = api.get(profile_url(circle)).json["emergency_contacts"]
    assert listed == [saved]

    changed = api.put(
        url(circle, f"/emergency-contacts/{saved['id']}"),
        contact("Khaled", "son", "+966522222222"),
    )
    assert changed.status_code == 200
    assert changed.json["emergency_contact"] == {
        "id": saved["id"],
        "name": "Khaled",
        "relation": "son",
        "phone_number": "+966522222222",
    }

    gone = api.delete(url(circle, f"/emergency-contacts/{saved['id']}"))
    assert gone.status_code == 204
    assert api.get(profile_url(circle)).json["emergency_contacts"] == []


def test_the_same_number_cannot_be_a_contact_twice(setup):
    api, circle = setup
    api.post(url(circle, "/emergency-contacts"), contact())

    again = api.post(url(circle, "/emergency-contacts"), contact("Other"))
    other = api.post(
        url(circle, "/emergency-contacts"), contact(phone="+966522222222")
    ).json["emergency_contact"]
    clash = api.put(
        url(circle, f"/emergency-contacts/{other['id']}"), contact()
    )

    assert error_code(again, 422) == "duplicate_contact"
    assert error_code(clash, 422) == "duplicate_contact"
    keep = api.put(
        url(circle, f"/emergency-contacts/{other['id']}"),
        contact("Renamed", phone="+966522222222"),
    )
    assert keep.status_code == 200


def test_a_patient_has_at_most_five_contacts(setup):
    api, circle = setup
    for index in range(5):
        response = api.post(
            url(circle, "/emergency-contacts"),
            contact(phone=f"+96651000000{index}"),
        )
        assert response.status_code == 201

    sixth = api.post(
        url(circle, "/emergency-contacts"), contact(phone="+966519999999")
    )

    assert error_code(sixth, 422) == "too_many_contacts"


@pytest.mark.parametrize(
    "body",
    [
        {"name": "", "relation": "son", "phone_number": PHONE},
        {"name": "Reem", "relation": "cousin", "phone_number": PHONE},
        {"name": "Reem", "relation": "son", "phone_number": "0511111111"},
        {"name": "Reem", "relation": "son"},
    ],
)
def test_a_wrong_contact_is_refused(setup, body):
    api, circle = setup

    response = api.post(url(circle, "/emergency-contacts"), body)

    assert error_code(response, 422) == "validation_error"


def test_a_contact_is_only_reachable_through_its_own_circle(
    database_app, database, account
):
    owner, other_owner = account(), account()
    mine = offline_circle(database, owner)
    theirs = offline_circle(database, other_owner)
    theirs_api = Api(database_app, other_owner)
    foreign = theirs_api.post(
        url(theirs, "/emergency-contacts"), contact()
    ).json["emergency_contact"]
    api = Api(database_app, owner)
    address = url(mine, f"/emergency-contacts/{foreign['id']}")

    assert error_code(api.put(address, contact("Taken")), 404) == "not_found"
    assert error_code(api.delete(address), 404) == "not_found"
    assert (
        error_code(api.delete(url(mine, "/emergency-contacts/not-an-id")), 404)
        == "not_found"
    )
    still = theirs_api.get(profile_url(theirs)).json["emergency_contacts"]
    assert still[0]["name"] == "Reem"


# ---- the database refuses wrong data even without the API ----------------


@pytest.mark.parametrize(
    "statement",
    [
        "UPDATE patient SET blood_type = 'X+'",
        "INSERT INTO patient_condition (patient_id, code) "
        "SELECT id, 'flu' FROM patient",
        "INSERT INTO patient_condition (patient_id, code) "
        "SELECT id, 'other' FROM patient",
        "INSERT INTO patient_condition (patient_id, code, other_text) "
        "SELECT id, 'asthma', 'text' FROM patient",
        "INSERT INTO patient_allergy (patient_id, kind, code) "
        "SELECT id, 'none', 'milk' FROM patient",
        "INSERT INTO patient_allergy (patient_id, kind, code) "
        "SELECT id, 'food', 'penicillin' FROM patient",
        "INSERT INTO patient_allergy (patient_id, kind, code) "
        "SELECT id, 'drink', 'milk' FROM patient",
        "INSERT INTO emergency_contact (patient_id, name, relation, "
        "phone_number) SELECT id, 'A', 'cousin', '+966511111111' FROM patient",
        "INSERT INTO emergency_contact (patient_id, name, relation, "
        "phone_number) SELECT id, 'A', 'son', 'not-a-phone' FROM patient",
        "INSERT INTO emergency_contact (patient_id, name, relation, "
        "phone_number) SELECT id, '  ', 'son', '+966511111111' FROM patient",
    ],
)
def test_database_rules_hold_without_the_api(database, account, statement):
    offline_circle(database, account())

    with pytest.raises(IntegrityError):
        with database.begin() as connection:
            connection.execute(text(statement))


def test_the_database_keeps_each_choice_once(database, account):
    offline_circle(database, account())
    insert = (
        "INSERT INTO patient_condition (patient_id, code) "
        "SELECT id, 'asthma' FROM patient"
    )
    with database.begin() as connection:
        connection.execute(text(insert))

    with pytest.raises(IntegrityError):
        with database.begin() as connection:
            connection.execute(text(insert))


# ---- two edits at the same time ----------------------------------------


def test_two_managers_editing_at_the_same_time_do_not_collide(
    database, account
):
    """Both edits finish; the circle lock makes the second one wait."""
    owner, member = account(), account()
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, member)
    barrier = Barrier(2)

    def edit(actor, codes):
        with Session(database, expire_on_commit=False) as session:
            with session.begin():
                service = MedicalService(session, NOW)
                barrier.wait(timeout=10)
                service.update_profile(
                    actor.id,
                    circle.id,
                    MedicalUpdate(conditions=Conditions("listed", codes)),
                )

    with ThreadPoolExecutor(max_workers=2) as pool:
        first = pool.submit(edit, owner, ("heart", "asthma"))
        second = pool.submit(edit, member, ("asthma", "kidney"))
        first.result(timeout=30)
        second.result(timeout=30)

    with Session(database) as session:
        codes = sorted(
            session.scalars(text("SELECT code FROM patient_condition"))
        )
    assert codes in (["asthma", "heart"], ["asthma", "kidney"])
