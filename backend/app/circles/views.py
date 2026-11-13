"""Turn stored rows into the plain values the API returns.

Ids are returned as text with hyphens, like the circle ids of GET /home.
Times are ISO 8601 with the UTC offset. Phone numbers of other people are
only returned where the screen needs them.
"""

from datetime import datetime, timedelta
from uuid import UUID

from sqlalchemy import and_, func, or_, select
from sqlalchemy.orm import Session, aliased

from app.accounts import recorder_response
from app.authz.roles import CircleRole
from app.circles import naming
from app.circles.leader import AREAS, edit_access, leader_id
from app.circles.leader import patient_leads
from app.models import Account, CareCircle, CareCircleInvitation
from app.models import CareCircleManager, CareCircleRequest
from app.models import EmergencyContact
from app.medical import MedicalProfile

# How long the sender still sees a declined request in their list.
DECLINED_VISIBLE_DAYS = 7


def _time(value: datetime | None) -> str | None:
    """A time as ISO 8601 text, or None."""
    return value.isoformat() if value else None


def patient_view(session: Session, patient: CareCircle, viewer: UUID) -> dict:
    """Basic data of the patient. Names and avatar come from the account
    while linked: one person, one picture, like their photo."""
    # A patient with an account shows the account's names and picture; one
    # without shows the circle's.
    linked = (
        session.get(Account, patient.account_id)
        if patient.account_id
        else None
    )
    source = linked if linked else patient
    return {
        "first_name": source.first_name,
        "last_name": source.last_name,
        "birth_date": source.birth_date.isoformat(),
        "city": source.city,
        # Every time of the circle is wall clock in this IANA zone.
        "time_zone": patient.time_zone,
        "latitude": patient.latitude,
        "longitude": patient.longitude,
        "has_account": linked is not None,
        "app_mode": linked.app_mode if linked else None,
        "is_you": linked is not None and linked.id == viewer,
        "avatar_code": source.avatar_code,
    }


def circle_view(
    session: Session, circle_id: UUID, viewer: UUID, role: CircleRole
) -> dict:
    """The circle page: patient, members, and (managers only) invitations."""
    circle = session.get(CareCircle, circle_id)
    patient = circle
    # `is_patient` marks the manager who is also the patient, so the app
    # can show who the file belongs to.
    patient_account = patient.account_id if patient is not None else None
    leader = leader_id(session, circle)

    def member(membership, name, avatar_code, phone_number) -> dict:
        account_id = membership.account_id
        access = edit_access(membership, account_id == leader)
        edits = any(access.values())
        return {
            "account_id": str(account_id),
            "display_name": name,
            "is_you": account_id == viewer,
            "is_patient": account_id == patient_account,
            # The one who removes members and says who edits what.
            "is_leader": account_id == leader,
            "role": "manager" if edits else "member",
            # Each area this member may edit; `can_edit` (any of them) for
            # the app before the areas.
            "edit_access": access,
            "can_edit": edits,
            # Already the account's own avatar; a patient who manages their
            # own circle shares it, like their photo.
            "avatar_code": avatar_code,
            # So any circle member can call another, the same as an
            # emergency contact's number.
            "phone_number": phone_number,
        }

    members = [
        member(*row)
        for row in sorted(
            session.execute(
                select(CareCircleManager, Account.display_name,
                       Account.avatar_code, Account.phone_number)
                .join(Account, Account.id == CareCircleManager.account_id)
                .where(CareCircleManager.care_circle_id == circle_id)
            ).all(),
            # The patient, you, the leader, then by name.
            key=lambda row: (row[0].account_id != patient_account,
                             row[0].account_id != viewer,
                             row[0].account_id != leader, row[1] or "",
                             str(row[0].account_id)),
        )
    ]
    if patient_account is not None and not any(
        member["is_patient"] for member in members
    ):
        linked = (
            session.get(Account, patient_account)
            if patient_account else None
        )
        patient_name = (
            f"{linked.first_name} {linked.last_name}" if linked
            else f"{patient.first_name} {patient.last_name}"
        )
        members.insert(0, {
            "account_id": str(patient_account) if patient_account else None,
            "display_name": patient_name.strip(),
            "is_you": patient_account == viewer,
            "is_patient": True,
            "is_leader": False,
            "role": "patient",
            "edit_access": {area: False for area in AREAS},
            "can_edit": False,
            "avatar_code": (
                linked.avatar_code if linked else patient.avatar_code
            ),
            "phone_number": linked.phone_number if linked else None,
        })
    linked_patient = (
        session.get(Account, patient_account) if patient_account else None
    )
    view = {
        "id": str(circle.id),
        # The patient sees their own name for it; the others «دائرة» and
        # the patient's name (`app.circles.naming`).
        "name": naming.name_for(
            viewer,
            own_name=circle.name,
            patient_account_id=patient_account,
            patient_account_name=naming.account_name(linked_patient),
            patient_first_name=patient.first_name,
        ),
        "role": role.value,
        "patient": patient_view(session, patient, viewer),
        "members": members,
        # The leader («قائد الدائرة», `app.circles.leader`): only they
        # remove members and say who edits what, and they may hand the
        # circle to another member unless the patient leads it.
        "leader_account_id": str(leader) if leader else None,
        "can_manage_members": leader == viewer,
        "can_hand_over": leader == viewer and not patient_leads(
            session, circle
        ),
        # What the viewer may edit here.
        "your_edit_access": next(
            (m["edit_access"] for m in members if m["is_you"]),
            {area: False for area in AREAS},
        ),
    }
    if role == CircleRole.MANAGER:
        view["pending_invitations"] = [
            invitation_view(invitation)
            for invitation in session.scalars(
                select(CareCircleInvitation)
                .where(
                    CareCircleInvitation.care_circle_id == circle_id,
                    CareCircleInvitation.status == "pending",
                )
                .order_by(
                    CareCircleInvitation.created_at.desc(),
                    CareCircleInvitation.id,
                )
            )
        ]
    return view


def invitation_view(invitation: CareCircleInvitation) -> dict:
    """An invitation as the managers of the circle see it."""
    return {
        "id": str(invitation.id),
        "invitee_phone_number": invitation.invitee_phone_number,
        "status": invitation.status,
        "created_at": _time(invitation.created_at),
        "last_sent_at": _time(invitation.last_sent_at),
    }


def contact_views(
    session: Session, contacts: list[EmergencyContact]
) -> list[dict]:
    """Emergency contacts, as the app reads them.

    A contact whose number is a TFAQUD account's is «متحقق» (`verified`).
    Its name and avatar (`account`) are shown only when that account is in
    the patient's circle, whose members see each other already; for anyone
    else only the mark is shown.
    """
    phones = {contact.phone_number for contact in contacts}
    accounts = {
        account.phone_number: account
        for account in (
            session.scalars(
                select(Account).where(Account.phone_number.in_(phones))
            )
            if phones else ()
        )
    }
    # The circle's members and its patient's own account.
    circles = {contact.care_circle_id for contact in contacts}
    known = set()
    if circles:
        known.update(session.scalars(
            select(CareCircleManager.account_id).where(
                CareCircleManager.care_circle_id.in_(circles)
            )
        ))
        known.update(session.scalars(
            select(CareCircle.account_id).where(
                CareCircle.id.in_(circles),
                CareCircle.account_id.is_not(None),
            )
        ))
    return [
        _contact_view(contact, accounts.get(contact.phone_number), known)
        for contact in contacts
    ]


def contact_view(session: Session, contact: EmergencyContact) -> dict:
    """One emergency contact, as `contact_views` reads it."""
    return contact_views(session, [contact])[0]


def _contact_view(
    contact: EmergencyContact, account: Account | None, known: set
) -> dict:
    return {
        "id": str(contact.id),
        "name": contact.name,
        "relation": contact.relation,
        "phone_number": contact.phone_number,
        "verified": account is not None,
        "account": (
            recorder_response(account)
            if account is not None and account.id in known
            else None
        ),
    }


def medical_view(profile: MedicalProfile) -> dict:
    """The medical profile, as the app reads it."""
    return {
        "blood_type": profile.blood_type,
        "conditions": profile.conditions,
        "allergies": profile.allergies,
    }


def emergency_card_view(
    session: Session,
    patient: CareCircle,
    profile: MedicalProfile,
    contacts: list[EmergencyContact],
) -> dict:
    """The emergency card: only what a helper needs to read quickly.

    The card is shown to people who help in an emergency, so it carries no
    birth date, city or coordinates. Names come from the account while the
    patient is linked to one, like in `patient_view`.
    """
    linked = (
        session.get(Account, patient.account_id)
        if patient.account_id
        else None
    )
    source = linked if linked else patient
    return {
        "first_name": source.first_name,
        "last_name": source.last_name,
        **medical_view(profile),
        "emergency_contacts": contact_views(session, contacts),
    }


# ---- creation requests --------------------------------------------------


def sent_request_view(request: CareCircleRequest) -> dict:
    """A request as the person who sent it sees it."""
    return {
        "id": str(request.id),
        "patient_phone_number": request.patient_phone_number,
        "proposed_app_mode": request.proposed_app_mode,
        "status": request.status,
        "created_at": _time(request.created_at),
        "responded_at": _time(request.responded_at),
        "care_circle_id": (
            str(request.care_circle_id) if request.care_circle_id else None
        ),
    }


def received_request_view(
    request: CareCircleRequest, requester: Account
) -> dict:
    """A request as the person it is about (the future patient) sees it.

    The patient names the circle themself when they complete the request,
    so there is no circle name yet (`circle_name` is null).
    """
    return {
        "id": str(request.id),
        "status": request.status,
        "circle_name": None,
        "proposed_app_mode": request.proposed_app_mode,
        "requested_by": {
            "display_name": requester.display_name,
            "first_name": requester.first_name,
            "last_name": requester.last_name,
            "avatar_code": requester.avatar_code,
        },
        "created_at": _time(request.created_at),
    }


def creation_requests_view(
    session: Session, account: Account, now: datetime
) -> dict:
    """Requests the account sent, and requests that name its phone number."""
    request = CareCircleRequest
    recent = now - timedelta(days=DECLINED_VISIBLE_DAYS)
    # Sent: the open ones, and the declined ones for a few days so the sender
    # sees the answer.
    sent = session.scalars(
        select(request)
        .where(
            request.requested_by_account_id == account.id,
            or_(
                request.status.in_(["pending", "accepted"]),
                and_(
                    request.status == "declined", request.responded_at > recent
                ),
            ),
        )
        .order_by(request.created_at.desc(), request.id)
    ).all()
    # Received: the open ones naming this account's number, with who sent each.
    received = session.execute(
        select(request, Account)
        .join(Account, Account.id == request.requested_by_account_id)
        .where(
            request.patient_phone_number == account.phone_number,
            request.status.in_(["pending", "accepted"]),
        )
        .order_by(request.created_at.desc(), request.id)
    ).all()
    return {
        "sent": [sent_request_view(row) for row in sent],
        "received": [
            received_request_view(row, requester)
            for row, requester in received
        ],
    }


# ---- received invitations --------------------------------------------


def received_invitations_view(
    session: Session, account: Account
) -> list[dict]:
    """Pending invitations addressed to this account's phone number."""
    invitation = CareCircleInvitation
    inviter = aliased(Account)
    patient_account = aliased(Account)
    rows = session.execute(
        select(
            invitation,
            CareCircle.name,
            inviter.display_name,
            inviter.avatar_code,
            CareCircle.account_id,
            CareCircle.first_name,
            patient_account.display_name.label("patient_display_name"),
            patient_account.first_name.label("patient_account_first_name"),
        )
        .join(CareCircle, CareCircle.id == invitation.care_circle_id)
        .outerjoin(inviter, inviter.id == invitation.invited_by_account_id)
        .outerjoin(
            patient_account, patient_account.id == CareCircle.account_id
        )
        .where(
            invitation.invitee_phone_number == account.phone_number,
            invitation.status == "pending",
        )
        .order_by(invitation.created_at.desc(), invitation.id)
    ).all()
    return [
        {
            "id": str(row[0].id),
            # As the invited person will see it: «دائرة» and the patient's
            # name, never the patient's own choice.
            "circle_name": naming.name_for(
                account.id,
                own_name=row.name,
                patient_account_id=row.account_id,
                patient_account_name=(
                    row.patient_display_name or row.patient_account_first_name
                ),
                patient_first_name=row.first_name,
            ),
            "invited_by": (
                {
                    "display_name": row.display_name,
                    "avatar_code": row.avatar_code,
                }
                if row.display_name
                else None
            ),
            "created_at": _time(row[0].created_at),
            "last_sent_at": _time(row[0].last_sent_at),
        }
        for row in rows
    ]


# ---- the bell's «السابقة» -------------------------------------------

# How long an answered invitation or request stays in «السابقة».
PREVIOUS_VISIBLE_DAYS = 30


def previous_notifications_view(
    session: Session, account: Account, now: datetime
) -> list[dict]:
    """What was answered in the last 30 days, newest first: invitations to
    this account and from it, and circle requests about it and from it.

    Each item says what it was (`kind`), how it ended (`status`), when
    (`answered_at`), the circle's name as this account reads it, and the
    other person (`other_name` and `other_avatar_code`, or
    `other_phone_number` for someone who has no name here)."""
    since = now - timedelta(days=PREVIOUS_VISIBLE_DAYS)
    items: list[dict] = []
    other = aliased(Account)
    patient = aliased(Account)

    def circle_name(circle: CareCircle | None, patient_account) -> str | None:
        if circle is None:
            return None
        return naming.name_for(
            account.id,
            own_name=circle.name,
            patient_account_id=circle.account_id,
            patient_account_name=naming.account_name(patient_account),
            patient_first_name=circle.first_name,
        )

    invitation = CareCircleInvitation
    answered = invitation.status.in_(["accepted", "declined"])
    for kind, mine in (
        ("invitation_received",
         invitation.invitee_phone_number == account.phone_number),
        ("invitation_sent", invitation.invited_by_account_id == account.id),
    ):
        person = (
            invitation.invited_by_account_id
            if kind == "invitation_received"
            else invitation.responded_by_account_id
        )
        rows = session.execute(
            select(invitation, CareCircle, other, patient)
            .join(CareCircle, CareCircle.id == invitation.care_circle_id)
            .outerjoin(other, other.id == person)
            .outerjoin(patient, patient.id == CareCircle.account_id)
            .where(mine, answered, invitation.responded_at > since)
        ).all()
        for row, circle, person_account, patient_account in rows:
            items.append({
                "id": str(row.id),
                "kind": kind,
                "status": row.status,
                "answered_at": _time(row.responded_at),
                "circle_name": circle_name(circle, patient_account),
                "other_name": naming.account_name(person_account),
                "other_avatar_code": (
                    person_account.avatar_code if person_account else None
                ),
                "other_phone_number": (
                    row.invitee_phone_number
                    if kind == "invitation_sent" and person_account is None
                    else None
                ),
            })

    request = CareCircleRequest
    done = request.status.in_(["completed", "declined"])
    when = func.coalesce(request.completed_at, request.responded_at)
    for kind, mine, person in (
        ("request_received",
         request.patient_phone_number == account.phone_number,
         request.requested_by_account_id),
        ("request_sent", request.requested_by_account_id == account.id,
         request.responded_by_account_id),
    ):
        rows = session.execute(
            select(request, CareCircle, other, patient)
            .outerjoin(CareCircle, CareCircle.id == request.care_circle_id)
            .outerjoin(other, other.id == person)
            .outerjoin(patient, patient.id == CareCircle.account_id)
            .where(mine, done, when > since)
        ).all()
        for row, circle, person_account, patient_account in rows:
            items.append({
                "id": str(row.id),
                "kind": kind,
                "status": row.status,
                "answered_at": _time(row.completed_at or row.responded_at),
                "circle_name": circle_name(circle, patient_account),
                "other_name": naming.account_name(person_account),
                "other_avatar_code": (
                    person_account.avatar_code if person_account else None
                ),
                "other_phone_number": (
                    row.patient_phone_number
                    if kind == "request_sent" and person_account is None
                    else None
                ),
            })
    return sorted(
        items, key=lambda item: (item["answered_at"], item["id"]),
        reverse=True,
    )
