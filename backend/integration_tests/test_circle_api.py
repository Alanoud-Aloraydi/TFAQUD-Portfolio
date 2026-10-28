"""Circle endpoints through Flask against real PostgreSQL."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account, CareCircle, CareCircleManager, Patient
from integration_tests.helpers import Api, BIRTH, add_manager, count
from integration_tests.helpers import error_code, offline_circle, run

SELF = {"name": "My care", "birth_date": "1954-06-05", "city": "Riyadh"}
OFFLINE = {
    "name": "Mother Nora",
    "patient_first_name": "Nora",
    "patient_last_name": "Family",
    "birth_date": "1950-01-02",
    "city": "Buraydah",
}


def circle_url(circle_id, tail=""):
    return f"/api/v1/circles/{circle_id}{tail}"


def simplified_circle(database, requester, patient):
    """A circle for a patient who uses Simplified Mode and manages nothing."""
    request = run(
        database,
        "request_creation",
        requester.id,
        patient.phone_number,
        "Mother",
        "simplified",
    )
    run(database, "respond_creation", patient.id, request.id, True)
    return run(
        database, "complete_creation", patient.id, request.id, BIRTH, "Riyadh"
    )


# ---- create --------------------------------------------------------------


def test_self_care_circle_is_created_and_listed(
    database_app, database, account
):
    owner = account()
    api = Api(database_app, owner)

    response = api.post(
        "/api/v1/circles/self",
        {**SELF, "latitude": 24.7136, "longitude": 46.6753},
    )

    assert response.status_code == 201
    assert response.headers["Cache-Control"] == "no-store"
    circle = response.json["circle"]
    assert circle["name"] == "My care"
    assert circle["role"] == "manager"
    assert circle["patient"] == {
        "first_name": "Nora",
        "last_name": "Family",
        "birth_date": "1954-06-05",
        "city": "Riyadh",
        "latitude": 24.7136,
        "longitude": 46.6753,
        "has_account": True,
        "app_mode": "detailed",
        "is_you": True,
    }
    assert circle["members"] == [
        {"display_name": "Nora", "is_you": True, "role": "manager"}
    ]
    assert circle["pending_invitations"] == []
    home = api.get("/api/v1/home")
    assert home.json["care_circles"] == [
        {
            "id": circle["id"],
            "name": "My care",
            "can_manage_medications": True,
        }
    ]
    with Session(database) as session:
        assert session.get(Account, owner.id).app_mode == "detailed"


def test_the_account_page_tells_which_circle_the_account_receives_care_in(
    database_app, database, account
):
    """The app asks this before it shows the pages that create a circle."""
    api = Api(database_app, account())
    assert api.get("/api/v1/accounts/me").json["account"][
        "patient_circle_id"
    ] is None

    created = api.post("/api/v1/circles/self", SELF)

    assert api.get("/api/v1/accounts/me").json["account"][
        "patient_circle_id"
    ] == created.json["circle"]["id"]


def test_managing_the_circle_of_someone_else_is_not_receiving_care(
    database_app, database, account
):
    owner = account()
    offline_circle(database, owner)

    response = Api(database_app, owner).get("/api/v1/accounts/me")

    assert response.json["account"]["patient_circle_id"] is None


def test_a_second_self_care_circle_is_refused(database_app, database, account):
    api = Api(database_app, account())
    assert api.post("/api/v1/circles/self", SELF).status_code == 201

    response = api.post("/api/v1/circles/self", SELF)

    assert error_code(response, 422) == "already_has_circle"
    assert count(database, CareCircle) == 1


def test_an_account_without_a_profile_cannot_create_a_circle(
    database_app, database, account
):
    api = Api(database_app, account(complete=False))

    response = api.post("/api/v1/circles/self", SELF)

    assert error_code(response, 422) == "profile_incomplete"
    assert count(database, CareCircle) == 0


def test_a_birth_date_in_the_future_is_refused(
    database_app, database, account
):
    api = Api(database_app, account())

    response = api.post(
        "/api/v1/circles/self", {**SELF, "birth_date": "2999-01-01"}
    )

    assert error_code(response, 422) == "invalid_birth_date"
    assert count(database, CareCircle) == 0


def test_a_bad_medical_part_creates_nothing(database_app, database, account):
    """The circle and its medical data are saved together or not at all."""
    owner = account()
    api = Api(database_app, owner)
    body = {
        **SELF,
        "medical_profile": {
            "conditions": {"status": "listed", "codes": ["other"]}
        },
    }

    response = api.post("/api/v1/circles/self", body)

    assert error_code(response, 422) == "other_text_required"
    assert count(database, CareCircle) == 0
    assert count(database, Patient) == 0
    with Session(database) as session:
        assert session.get(Account, owner.id).app_mode is None


def test_circle_for_a_patient_without_an_account(
    database_app, database, account
):
    owner = account()
    api = Api(database_app, owner)

    response = api.post("/api/v1/circles/patient-without-account", OFFLINE)

    assert response.status_code == 201
    circle = response.json["circle"]
    assert circle["name"] == "Mother Nora"
    assert circle["patient"]["has_account"] is False
    assert circle["patient"]["is_you"] is False
    assert circle["patient"]["app_mode"] is None
    assert circle["patient"]["first_name"] == "Nora"
    assert circle["members"] == [
        {"display_name": "Nora", "is_you": True, "role": "manager"}
    ]
    with Session(database) as session:
        patient = session.scalar(select(Patient))
        assert patient.account_id is None
        assert session.get(Account, owner.id).app_mode == "detailed"


def test_circle_for_a_patient_without_an_account_needs_both_names(
    database_app, account
):
    api = Api(database_app, account())
    body = {k: v for k, v in OFFLINE.items() if k != "patient_last_name"}

    response = api.post("/api/v1/circles/patient-without-account", body)

    assert error_code(response, 422) == "validation_error"


# ---- read ----------------------------------------------------------------


def test_a_stranger_gets_the_same_refusal_for_any_circle(
    database_app, database, account
):
    owner, stranger = account(), account()
    circle = offline_circle(database, owner)
    api = Api(database_app, stranger)

    real = api.get(circle_url(circle.id))
    unknown = api.get(circle_url("33333333-3333-4333-8333-333333333333"))
    garbage = api.get(circle_url("not-an-id"))

    for response in (real, unknown, garbage):
        assert error_code(response, 403) == "forbidden"
    assert unknown.json["error"]["message"] == real.json["error"]["message"]


def test_the_circle_page_lists_members_you_first(
    database_app, database, account
):
    owner, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, khaled)

    reem = Api(database_app, owner).get(circle_url(circle.id)).json["circle"]
    khaled_view = (
        Api(database_app, khaled).get(circle_url(circle.id)).json["circle"]
    )

    assert [m["display_name"] for m in reem["members"]] == ["Reem", "Khaled"]
    assert [m["is_you"] for m in reem["members"]] == [True, False]
    assert [m["display_name"] for m in khaled_view["members"]] == [
        "Khaled",
        "Reem",
    ]


def test_a_simplified_patient_sees_the_circle_without_invitations(
    database_app, database, account
):
    owner, patient = account(), account(name="Noura")
    circle = simplified_circle(database, owner, patient)
    run(database, "invite_manager", owner.id, circle.id, "+966511111111")

    view = Api(database_app, patient).get(circle_url(circle.id)).json["circle"]

    assert view["role"] == "simplified_patient"
    assert "pending_invitations" not in view
    assert view["patient"]["is_you"] is True
    assert view["patient"]["app_mode"] == "simplified"
    assert len(view["members"]) == 1


# ---- rename and patient data ---------------------------------------------


def test_a_manager_renames_the_circle(database_app, database, account):
    owner = account()
    circle = offline_circle(database, owner)
    api = Api(database_app, owner)

    response = api.patch(circle_url(circle.id), {"name": "  Grandma Noura "})

    assert response.status_code == 200
    assert response.json["circle"]["name"] == "Grandma Noura"
    with Session(database) as session:
        assert session.get(CareCircle, circle.id).name == "Grandma Noura"


def test_a_blank_circle_name_is_refused(database_app, database, account):
    owner = account()
    circle = offline_circle(database, owner)

    response = Api(database_app, owner).patch(
        circle_url(circle.id), {"name": "   "}
    )

    assert error_code(response, 422) == "validation_error"


def test_a_simplified_patient_cannot_rename_the_circle(
    database_app, database, account
):
    owner, patient = account(), account()
    circle = simplified_circle(database, owner, patient)

    response = Api(database_app, patient).patch(
        circle_url(circle.id), {"name": "Mine now"}
    )

    assert error_code(response, 403) == "forbidden"


def test_a_manager_edits_the_data_of_a_patient_without_an_account(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)

    response = Api(database_app, owner).put(
        circle_url(circle.id, "/patient"),
        {
            "birth_date": "1951-03-04",
            "city": "Jeddah",
            "first_name": "Noura",
            "last_name": "Salem",
            "latitude": 21.5,
            "longitude": 39.2,
        },
    )

    assert response.status_code == 200
    patient = response.json["circle"]["patient"]
    assert patient["first_name"] == "Noura"
    assert patient["city"] == "Jeddah"
    assert patient["birth_date"] == "1951-03-04"
    assert patient["latitude"] == 21.5


def test_a_patient_without_an_account_keeps_both_names_required(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)

    response = Api(database_app, owner).put(
        circle_url(circle.id, "/patient"),
        {"birth_date": "1951-03-04", "city": "Jeddah"},
    )

    assert error_code(response, 422) == "patient_name_required"


def test_names_of_a_patient_with_an_account_come_from_the_account(
    database_app, database, account
):
    owner = account()
    circle = run(database, "create_self", owner.id, "Care", BIRTH, "Riyadh")

    response = Api(database_app, owner).put(
        circle_url(circle.id, "/patient"),
        {
            "birth_date": "1954-06-05",
            "city": "Riyadh",
            "first_name": "Other",
            "last_name": "Name",
        },
    )

    assert error_code(response, 422) == "linked_patient_name"


def test_a_simplified_patient_edits_their_own_data(
    database_app, database, account
):
    owner, patient = account(), account()
    circle = simplified_circle(database, owner, patient)

    response = Api(database_app, patient).put(
        circle_url(circle.id, "/patient"),
        {"birth_date": "1950-01-01", "city": "Madinah"},
    )

    assert response.status_code == 200
    assert response.json["circle"]["patient"]["city"] == "Madinah"
    assert response.json["circle"]["role"] == "simplified_patient"


# ---- leave and delete ------------------------------------------------


def test_a_manager_leaves_and_loses_access(database_app, database, account):
    owner, member = account(), account()
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, member)
    api = Api(database_app, member)

    response = api.post(circle_url(circle.id, "/leave"))

    assert response.status_code == 204
    assert error_code(api.get(circle_url(circle.id)), 403) == "forbidden"
    assert api.get("/api/v1/home").json["care_circles"] == []
    assert (
        Api(database_app, owner).get(circle_url(circle.id)).status_code == 200
    )


def test_the_last_manager_must_confirm_deleting_the_circle(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    api = Api(database_app, owner)

    refused = api.post(circle_url(circle.id, "/leave"), {})
    assert error_code(refused, 422) == "confirmation_required"
    assert count(database, CareCircle) == 1

    done = api.post(circle_url(circle.id, "/leave"), {"confirm_delete": True})
    assert done.status_code == 204
    assert count(database, CareCircle) == 0
    assert count(database, Patient) == 0


def test_deleting_a_circle_needs_the_confirmation_in_the_url(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    api = Api(database_app, owner)

    refused = api.delete(circle_url(circle.id))
    assert error_code(refused, 422) == "confirmation_required"

    done = api.delete(circle_url(circle.id) + "?confirm=true")
    assert done.status_code == 204
    assert count(database, CareCircle) == 0


def test_a_manager_cannot_delete_a_circle_that_has_other_managers(
    database_app, database, account
):
    owner, member = account(), account()
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, member)

    response = Api(database_app, owner).delete(
        circle_url(circle.id) + "?confirm=true"
    )

    assert error_code(response, 403) == "forbidden"
    assert count(database, CareCircle) == 1


def test_the_patient_can_delete_their_circle(database_app, database, account):
    owner, patient = account(), account()
    circle = simplified_circle(database, owner, patient)

    response = Api(database_app, patient).delete(
        circle_url(circle.id) + "?confirm=true"
    )

    assert response.status_code == 204
    assert count(database, CareCircle) == 0
    assert count(database, Account) == 2


def test_nothing_is_left_when_a_circle_is_deleted(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    api = Api(database_app, owner)
    api.patch(circle_url(circle.id, "/medical-profile"), {"blood_type": "O+"})
    api.post(
        circle_url(circle.id, "/emergency-contacts"),
        {
            "name": "Reem",
            "relation": "daughter",
            "phone_number": "+966511111111",
        },
    )

    api.delete(circle_url(circle.id) + "?confirm=true")

    from app.models import EmergencyContact

    assert count(database, EmergencyContact) == 0
    assert count(database, CareCircleManager) == 0


# ---- invitations ----------------------------------------------------------


def test_invitation_from_sending_to_accepting(database_app, database, account):
    owner, guest = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, owner)
    manager, invited = Api(database_app, owner), Api(database_app, guest)

    sent = manager.post(
        circle_url(circle.id, "/invitations"),
        {"invitee_phone_number": guest.phone_number},
    )
    assert sent.status_code == 201
    invitation = sent.json["invitation"]
    assert invitation["status"] == "pending"
    assert invitation["invitee_phone_number"] == guest.phone_number

    page = manager.get(circle_url(circle.id)).json["circle"]
    assert [i["id"] for i in page["pending_invitations"]] == [invitation["id"]]

    received = invited.get("/api/v1/invitations").json["invitations"]
    assert len(received) == 1
    assert received[0]["id"] == invitation["id"]
    assert received[0]["circle_name"] == circle.name
    assert received[0]["invited_by"] == {"display_name": "Reem"}
    # The invited person is not told the circle id before accepting.
    assert "care_circle_id" not in received[0]
    assert error_code(invited.get(circle_url(circle.id)), 403) == "forbidden"

    accepted = invited.post(
        f"/api/v1/invitations/{invitation['id']}/respond", {"accept": True}
    )
    assert accepted.status_code == 200
    assert accepted.json["invitation"]["status"] == "accepted"
    assert accepted.json["invitation"]["care_circle_id"] == str(circle.id)
    view = invited.get(circle_url(circle.id)).json["circle"]
    assert [m["display_name"] for m in view["members"]] == ["Khaled", "Reem"]
    assert invited.get("/api/v1/invitations").json["invitations"] == []
    assert (
        manager.get(circle_url(circle.id)).json["circle"][
            "pending_invitations"
        ]
        == []
    )


def test_declining_an_invitation_gives_no_access(
    database_app, database, account
):
    owner, guest = account(), account()
    circle = offline_circle(database, owner)
    invitation = run(
        database, "invite_manager", owner.id, circle.id, guest.phone_number
    )
    invited = Api(database_app, guest)

    declined = invited.post(
        f"/api/v1/invitations/{invitation.id}/respond", {"accept": False}
    )

    assert declined.json["invitation"] == {
        "id": str(invitation.id),
        "status": "declined",
        "care_circle_id": None,
    }
    assert error_code(invited.get(circle_url(circle.id)), 403) == "forbidden"


def test_an_invitation_is_hidden_from_everyone_else(
    database_app, database, account
):
    owner, guest, stranger = account(), account(), account()
    circle = offline_circle(database, owner)
    invitation = run(
        database, "invite_manager", owner.id, circle.id, guest.phone_number
    )

    response = Api(database_app, stranger).post(
        f"/api/v1/invitations/{invitation.id}/respond", {"accept": True}
    )

    assert error_code(response, 404) == "not_found"
    unknown = Api(database_app, stranger).post(
        "/api/v1/invitations/not-an-id/respond", {"accept": True}
    )
    assert error_code(unknown, 404) == "not_found"


def test_inviting_yourself_or_a_current_manager_is_refused(
    database_app, database, account
):
    owner, member = account(), account()
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, member)
    api = Api(database_app, owner)
    url = circle_url(circle.id, "/invitations")

    own = api.post(url, {"invitee_phone_number": owner.phone_number})
    existing = api.post(url, {"invitee_phone_number": member.phone_number})

    assert error_code(own, 422) == "self_invitation"
    assert error_code(existing, 422) == "already_manager"


def test_inviting_the_same_number_again_sends_the_same_invitation(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    api = Api(database_app, owner)
    url = circle_url(circle.id, "/invitations")
    body = {"invitee_phone_number": "+966511111111"}

    first = api.post(url, body).json["invitation"]
    second = api.post(url, body).json["invitation"]

    assert first["id"] == second["id"]
    assert second["last_sent_at"] >= first["last_sent_at"]


def test_resending_and_canceling_an_invitation(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    invitation = run(
        database, "invite_manager", owner.id, circle.id, "+966511111111"
    )
    api = Api(database_app, owner)
    url = circle_url(circle.id, f"/invitations/{invitation.id}")

    resent = api.post(url + "/resend")
    assert resent.status_code == 200
    assert resent.json["invitation"]["id"] == str(invitation.id)

    assert api.delete(url).status_code == 204
    page = api.get(circle_url(circle.id)).json["circle"]
    assert page["pending_invitations"] == []
    assert (
        error_code(api.post(url + "/resend"), 422) == "invitation_not_pending"
    )
    assert api.delete(url).status_code == 204  # canceling twice is harmless


def test_an_invitation_cannot_be_reached_through_another_circle(
    database_app, database, account
):
    owner = account()
    mine = offline_circle(database, owner)
    other_owner = account()
    theirs = offline_circle(database, other_owner)
    invitation = run(
        database, "invite_manager", other_owner.id, theirs.id, "+966511111111"
    )
    api = Api(database_app, owner)
    url = circle_url(mine.id, f"/invitations/{invitation.id}")

    assert error_code(api.post(url + "/resend"), 404) == "not_found"
    assert error_code(api.delete(url), 404) == "not_found"
    with Session(database) as session:
        from app.models import CareCircleManagerInvitation

        assert (
            session.get(CareCircleManagerInvitation, invitation.id).status
            == "pending"
        )
