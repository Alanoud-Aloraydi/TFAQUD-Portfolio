"""The scan deletes, against PostgreSQL, the rows nothing reads any more:
sessions signed out long ago, snoozes past their day, and invitations and
requests that led nowhere. What is still read stays."""

from datetime import datetime, time, timedelta, timezone
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import (
    AccountSession,
    CareCircleInvitation,
    CareCircleRequest,
    TaskSnooze,
)
from app.push.scheduled import purge_old_rows
from integration_tests.helpers import offline_circle

NOW = datetime.now(timezone.utc)
LONG_AGO = NOW - timedelta(days=31)
LATELY = NOW - timedelta(days=29)


def purge(database_app):
    with database_app.app_context():
        purge_old_rows(NOW)


def test_sessions_signed_out_a_month_ago_go(database_app, database, account):
    owner = account()
    with Session(database) as session, session.begin():
        for revoked in (LONG_AGO, LATELY, None):
            session.add(AccountSession(
                id=uuid4(), account_id=owner.id,
                refresh_token_hash=uuid4().hex * 2,
                created_at=NOW - timedelta(days=60), revoked_at=revoked,
            ))

    purge(database_app)

    with Session(database) as session:
        left = set(session.scalars(select(AccountSession.revoked_at)))
    assert left == {LATELY, None}


def test_snoozes_past_their_day_go(database_app, database, account):
    circle = offline_circle(database, account())
    with Session(database) as session, session.begin():
        for remind_at in (NOW - timedelta(days=3), NOW - timedelta(hours=1),
                          NOW + timedelta(minutes=30)):
            session.add(TaskSnooze(
                care_circle_id=circle.id, task="dose", task_id=uuid4(),
                scheduled_on=remind_at.date(), time_of_day=time(8),
                minutes=30, remind_at=remind_at,
            ))

    purge(database_app)

    with Session(database) as session:
        left = sorted(session.scalars(select(TaskSnooze.remind_at)))
    assert left == [NOW - timedelta(hours=1), NOW + timedelta(minutes=30)]


def test_invitations_that_led_nowhere_go_after_30_days(
    database_app, database, account
):
    owner = account()
    circle = offline_circle(database, owner)
    rows = {
        ("declined", LONG_AGO): False, ("cancelled", LONG_AGO): False,
        ("declined", LATELY): True, ("accepted", LONG_AGO): True,
        ("pending", LONG_AGO): True,
    }
    with Session(database) as session, session.begin():
        for number, (status, when) in enumerate(rows):
            session.add(CareCircleInvitation(
                care_circle_id=circle.id, invited_by_account_id=owner.id,
                invitee_phone_number=f"+96655000000{number}", status=status,
                created_at=when, last_sent_at=when,
                responded_at=None if status in ("pending", "cancelled")
                else when,
            ))

    purge(database_app)

    with Session(database) as session:
        left = {tuple(row) for row in session.execute(select(
            CareCircleInvitation.status, CareCircleInvitation.last_sent_at
        ))}
    assert left == {key for key, kept in rows.items() if kept}


def test_requests_that_led_nowhere_go_after_30_days(
    database_app, database, account
):
    owner = account()
    rows = {
        ("declined", LONG_AGO): False, ("cancelled", LONG_AGO): False,
        ("superseded", LONG_AGO): False, ("declined", LATELY): True,
        ("pending", LONG_AGO): True,
    }
    with Session(database) as session, session.begin():
        for number, (status, when) in enumerate(rows):
            session.add(CareCircleRequest(
                requested_by_account_id=owner.id,
                patient_phone_number=f"+96655100000{number}",
                proposed_app_mode="simplified", status=status,
                created_at=when,
                responded_at=None if status in ("pending", "cancelled")
                else when,
            ))

    purge(database_app)

    with Session(database) as session:
        left = {tuple(row) for row in session.execute(select(
            CareCircleRequest.status, CareCircleRequest.created_at
        ))}
    assert left == {key for key, kept in rows.items() if kept}
