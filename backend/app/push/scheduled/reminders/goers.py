"""Who hears of a visit (appointment_audience.dart): the patient, and the
members going with them; for a patient without a phone, a visit nobody goes
with reminds the circle's leader instead."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.circles.leader import leader_id
from app.models import CareCircle
from app.models.appointment import AppointmentCompanion


def visit_goers(
    session: Session, patient: CareCircle, visit_ids: list[UUID]
) -> dict[UUID, frozenset[UUID]]:
    """Each of the visits' goers, by its id, read in the caller's
    transaction."""
    going: dict[UUID, set[UUID]] = {visit_id: set() for visit_id in visit_ids}
    for visit_id, account_id in session.execute(
        select(
            AppointmentCompanion.appointment_id,
            AppointmentCompanion.account_id,
        ).where(AppointmentCompanion.appointment_id.in_(visit_ids))
    ):
        going[visit_id].add(account_id)
    stands_in = (
        leader_id(session, patient) if patient.account_id is None else None
    )
    return {
        visit_id: _goers(companions, patient, stands_in)
        for visit_id, companions in going.items()
    }


def _goers(
    companions: set[UUID], patient: CareCircle, stands_in: UUID | None
) -> frozenset[UUID]:
    """The patient and the companions; the leader of a patient without a
    phone when nobody goes with them."""
    goers = set(companions)
    if patient.account_id is not None:
        goers.add(patient.account_id)
    elif not goers and stands_in is not None:
        goers.add(stands_in)
    return frozenset(goers)
