"""The PostgreSQL store's requests: reading one, opening one, changing one."""

from uuid import uuid4

from sqlalchemy import update

from app.auth.otp_store import AttemptsExhausted, OtpRequest
from app.auth.postgres_otp.keys import request_key
from app.database import transaction
from app.models import OtpRequest as OtpRequestRow


class PostgresRequests:
    """Reads, opens and updates sign-in requests."""

    def get_request(self, request_id):
        """The request with this id, or None (also for an id that is not a
        UUID).
        """
        # An id that is not a UUID is no request.
        key = request_key(request_id)
        if key is None:
            return None
        with transaction() as session:
            row = session.get(OtpRequestRow, key)
            if row is None:
                return None
            return OtpRequest(
                id=row.id.hex,
                phone=row.phone_number,
                created_at=row.created_at,
                wrong_tries=row.wrong_try_count,
                verified_at=row.verified_at,
                status=row.status,
                expires_at=row.expires_at,
            )

    @staticmethod
    def _open_request(session, request_id, phone, now, max_tries):
        """Recheck a resend under lock, or supersede older open requests."""
        # A resend: this number's open request, locked, with tries left.
        if request_id is not None:
            key = request_key(request_id)
            row = (
                session.get(OtpRequestRow, key, with_for_update=True)
                if key
                else None
            )
            if (
                row is None
                or row.phone_number != phone
                or row.status != "pending"
            ):
                raise KeyError(request_id)
            if max_tries is not None and row.wrong_try_count >= max_tries:
                raise AttemptsExhausted()
            return row
        # A new request replaces the number's open one.
        session.execute(
            update(OtpRequestRow)
            .where(
                OtpRequestRow.phone_number == phone,
                OtpRequestRow.status == "pending",
            )
            .values(status="superseded")
        )
        row = OtpRequestRow(id=uuid4(), phone_number=phone, created_at=now)
        session.add(row)
        session.flush()
        return row

    @staticmethod
    def _update_request(request_id, condition, **values):
        """Check and change a pending request in one statement."""
        key = request_key(request_id)
        if key is None:
            return False
        # One statement checks and changes, so two calls at once cannot both
        # pass; True when a row changed.
        with transaction() as session:
            return (
                session.execute(
                    update(OtpRequestRow)
                    .where(
                        OtpRequestRow.id == key,
                        OtpRequestRow.status == "pending",
                        condition,
                    )
                    .values(**values)
                ).rowcount
                > 0
            )
