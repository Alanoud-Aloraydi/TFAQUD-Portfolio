"""Who sees which circle name (app/circles/naming.py), through Flask on
PostgreSQL.

- The patient with an account sees the name they chose.
- Everyone else sees «دائرة» and the patient's display name.
- A patient without an account: everyone sees «دائرة» and the first name.
"""

from integration_tests.helpers import Api, error_code

SELF = {"birth_date": "1950-01-02", "city": "Riyadh"}
OFFLINE = {
    "patient_first_name": "Huda",
    "patient_last_name": "Family",
    "birth_date": "1945-03-04",
    "city": "Riyadh",
}
REQUESTS = "/api/v1/circle-requests"


def home_names(api):
    return [c["name"] for c in api.get("/api/v1/home").json["care_circles"]]


def circle_name(api, circle_id):
    return api.get(f"/api/v1/circles/{circle_id}").json["circle"]["name"]


def invite_and_join(owner_api, member_api, circle_id):
    """The real invitation: sent by the owner, accepted by the member.
    Returns the circle name the invitation showed."""
    owner_api.post(
        f"/api/v1/circles/{circle_id}/invitations",
        {"invitee_phone_number": member_api.account.phone_number},
    )
    [invitation] = member_api.get("/api/v1/invitations").json["invitations"]
    member_api.post(
        f"/api/v1/invitations/{invitation['id']}/respond", {"accept": True}
    )
    return invitation["circle_name"]


def test_your_own_circle_shows_your_name_only_to_you(database_app, account):
    noura = Api(database_app, account(name="Noura"))
    reem = Api(database_app, account(name="Reem"))
    made = noura.post("/api/v1/circles/self", {"name": "صحتي", **SELF})
    assert made.status_code == 201
    circle_id = made.json["circle"]["id"]
    assert made.json["circle"]["name"] == "صحتي"

    shown_in_invitation = invite_and_join(noura, reem, circle_id)

    assert shown_in_invitation == "دائرة Noura"
    assert home_names(noura) == ["صحتي"]
    assert circle_name(noura, circle_id) == "صحتي"
    assert home_names(reem) == ["دائرة Noura"]
    assert circle_name(reem, circle_id) == "دائرة Noura"


def test_a_new_display_name_shows_at_once(database_app, account):
    noura = Api(database_app, account(name="Noura"))
    reem = Api(database_app, account(name="Reem"))
    circle_id = noura.post(
        "/api/v1/circles/self", {"name": "رعايتي", **SELF}
    ).json["circle"]["id"]
    invite_and_join(noura, reem, circle_id)

    noura.put(
        "/api/v1/accounts/me/profile",
        {"first_name": "Noura", "last_name": "Family", "display_name": "Nono"},
    )

    assert home_names(reem) == ["دائرة Nono"]
    assert home_names(noura) == ["رعايتي"]


def test_a_patient_without_a_number_is_named_for_everyone(
    database_app, account
):
    reem = Api(database_app, account(name="Reem"))
    khaled = Api(database_app, account(name="Khaled"))
    # An older app still sends a name; it is not used.
    made = reem.post(
        "/api/v1/circles/patient-without-account",
        {"name": "رعاية أمي", **OFFLINE},
    )
    assert made.status_code == 201
    circle_id = made.json["circle"]["id"]
    assert made.json["circle"]["name"] == "دائرة Huda"

    assert invite_and_join(reem, khaled, circle_id) == "دائرة Huda"
    assert home_names(reem) == ["دائرة Huda"]
    assert home_names(khaled) == ["دائرة Huda"]

    # A corrected first name shows at once.
    reem.put(
        f"/api/v1/circles/{circle_id}/patient",
        {**{k: OFFLINE[k] for k in ("birth_date", "city")},
         "first_name": "Hind", "last_name": "Family"},
    )
    assert circle_name(khaled, circle_id) == "دائرة Hind"


def test_the_new_app_makes_a_circle_without_a_name(database_app, account):
    reem = Api(database_app, account(name="Reem"))

    made = reem.post("/api/v1/circles/patient-without-account", OFFLINE)

    assert made.status_code == 201
    assert made.json["circle"]["name"] == "دائرة Huda"


def test_a_request_needs_no_label_and_the_patient_names_the_circle(
    database_app, account
):
    reem = Api(database_app, account(name="Reem"))
    noura = Api(database_app, account(name="Noura"))
    sent = reem.post(
        REQUESTS,
        {
            "patient_phone_number": noura.account.phone_number,
            "proposed_app_mode": "detailed",
        },
    )
    assert sent.status_code == 201
    request_id = sent.json["request"]["id"]
    noura.post(f"{REQUESTS}/{request_id}/respond", {"accept": True})

    done = noura.post(
        f"{REQUESTS}/{request_id}/complete", {**SELF, "name": "دائرتي الصحية"}
    )

    assert done.status_code == 201
    circle_id = done.json["circle"]["id"]
    assert home_names(noura) == ["دائرتي الصحية"]
    assert home_names(reem) == ["دائرة Noura"]
    assert circle_name(reem, circle_id) == "دائرة Noura"


def test_an_older_app_that_sends_no_name_gets_the_default(
    database_app, account
):
    reem = Api(database_app, account(name="Reem"))
    noura = Api(database_app, account(name="Noura"))
    request_id = reem.post(
        REQUESTS,
        {
            "patient_phone_number": noura.account.phone_number,
            "circle_label": "Mother",
            "proposed_app_mode": "simplified",
        },
    ).json["request"]["id"]
    noura.post(f"{REQUESTS}/{request_id}/respond", {"accept": True})

    done = noura.post(f"{REQUESTS}/{request_id}/complete", SELF)

    assert done.json["circle"]["name"] == "دائرتي"
    assert home_names(reem) == ["دائرة Noura"]


def test_only_the_patient_renames_the_circle(database_app, account):
    noura = Api(database_app, account(name="Noura"))
    reem = Api(database_app, account(name="Reem"))
    circle_id = noura.post(
        "/api/v1/circles/self", {"name": "صحتي", **SELF}
    ).json["circle"]["id"]
    invite_and_join(noura, reem, circle_id)

    renamed = noura.patch(f"/api/v1/circles/{circle_id}", {"name": "رعايتي"})
    refused = reem.patch(f"/api/v1/circles/{circle_id}", {"name": "أمي"})

    assert renamed.status_code == 200
    assert renamed.json["circle"]["name"] == "رعايتي"
    assert error_code(refused, 403) == "patient_names_circle"
    assert home_names(reem) == ["دائرة Noura"]


def test_a_simplified_patient_renames_their_own_circle(database_app, account):
    reem = Api(database_app, account(name="Reem"))
    noura = Api(database_app, account(name="Noura"))
    request_id = reem.post(
        REQUESTS,
        {
            "patient_phone_number": noura.account.phone_number,
            "proposed_app_mode": "simplified",
        },
    ).json["request"]["id"]
    noura.post(f"{REQUESTS}/{request_id}/respond", {"accept": True})
    circle_id = noura.post(
        f"{REQUESTS}/{request_id}/complete", {**SELF, "name": "صحتي"}
    ).json["circle"]["id"]

    renamed = noura.patch(f"/api/v1/circles/{circle_id}", {"name": "رعايتي"})

    assert renamed.status_code == 200
    assert renamed.json["circle"]["role"] == "simplified_patient"
    assert renamed.json["circle"]["name"] == "رعايتي"


def test_nobody_renames_a_circle_of_a_patient_without_a_number(
    database_app, account
):
    reem = Api(database_app, account(name="Reem"))
    circle_id = reem.post(
        "/api/v1/circles/patient-without-account", OFFLINE
    ).json["circle"]["id"]

    refused = reem.patch(f"/api/v1/circles/{circle_id}", {"name": "أمي"})

    assert error_code(refused, 403) == "patient_names_circle"
