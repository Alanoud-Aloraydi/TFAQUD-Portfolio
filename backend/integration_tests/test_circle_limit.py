"""At most six circles per person, counting the requests still open."""

import pytest

from app.care.rules import MAX_CIRCLES
from app.errors import ValidationFailed
from integration_tests.helpers import BIRTH, offline_circle, run


def refused(database, method, *args):
    """The code a refused operation answers."""
    with pytest.raises(ValidationFailed) as error:
        run(database, method, *args)
    return error.value.code


def test_a_seventh_circle_is_refused(database, account):
    owner = account()
    for _ in range(MAX_CIRCLES):
        offline_circle(database, owner)

    assert refused(
        database,
        "create_without_account",
        owner.id,
        "Nora",
        "Family",
        BIRTH,
        "Buraidah",
    ) == "too_many_circles"


def test_an_open_request_counts_and_a_cancelled_one_does_not(
    database, account
):
    owner, patient = account(), account()
    for _ in range(MAX_CIRCLES - 1):
        offline_circle(database, owner)
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "detailed",
    )

    assert refused(
        database,
        "create_self",
        owner.id,
        "Mine",
        BIRTH,
        "Buraidah",
    ) == "too_many_circles"

    run(database, "cancel_creation", owner.id, request.id)
    run(database, "create_self", owner.id, "Mine", BIRTH, "Buraidah")


def test_an_invitation_cannot_be_accepted_at_six(database, account):
    owner, invited = account(), account()
    circle = offline_circle(database, owner)
    for _ in range(MAX_CIRCLES):
        offline_circle(database, invited)
    invitation = run(
        database, "invite_manager", owner.id, circle.id, invited.phone_number
    )

    assert refused(
        database, "respond_invitation", invited.id, invitation.id, True
    ) == "too_many_circles"
    # Declining is always possible.
    run(database, "respond_invitation", invited.id, invitation.id, False)


def test_a_patient_at_six_cannot_accept_a_request(database, account):
    owner, patient = account(), account()
    for _ in range(MAX_CIRCLES):
        offline_circle(database, patient)
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "detailed",
    )

    assert refused(
        database, "respond_creation", patient.id, request.id, True
    ) == "too_many_circles"
