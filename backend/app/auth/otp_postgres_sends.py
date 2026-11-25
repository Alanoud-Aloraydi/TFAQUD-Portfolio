"""The PostgreSQL store's sends: the lock on one phone number, counting
the codes a send is judged by, and keeping each send's state once it is
judged."""

import hashlib
from uuid import UUID, uuid4

from sqlalchemy import func, select, text, update

from app.database import transaction
from app.models import OtpRequest as OtpRequestRow, OtpSend


def request_key(value):
    """Treat malformed public identifiers as missing records."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        return None


def lock_phone(session, phone):
    """Serialize phone quota claims, including phones without accounts."""
    digest = hashlib.sha256(phone.encode()).digest()[:8]
    session.execute(
        text("SELECT pg_advisory_xact_lock(:key)"),
        {"key": int.from_bytes(digest, "big", signed=True)},
    )


class PostgresSends:
    """Reserves a send and keeps its state."""

    @staticmethod
    def _reserve(session, row, now, rules):
        """Reserve one send for the request."""
        send = OtpSend(
            id=uuid4(),
            otp_request_id=row.id,
            created_at=now,
            device_id=rules.device_id,
            client_ip=rules.client_ip,
        )
        session.add(send)
        session.flush()
        return send

    def mark_sent(self, send_id, at, expires_at):
        """Mark the reserved send as sent, and keep the request open until the
        newest code's end.
        """
        # Only a reserved send becomes sent; the open request then lasts until
        # this code's end, never shorter.
        with transaction() as session:
            send = session.get(
                OtpSend, request_key(send_id), with_for_update=True
            )
            if send is None or send.status != "reserved":
                return
            send.status, send.sent_at = "sent", at
            session.execute(
                update(OtpRequestRow)
                .where(
                    OtpRequestRow.id == send.otp_request_id,
                    OtpRequestRow.status == "pending",
                    (OtpRequestRow.expires_at.is_(None))
                    | (OtpRequestRow.expires_at < expires_at),
                )
                .values(expires_at=expires_at)
            )

    def release_send(self, send_id):
        """Give a reserved place back: the provider refused, so no code left.
        """
        key = request_key(send_id)
        if key is None:
            return
        with transaction() as session:
            session.execute(
                update(OtpSend)
                .where(
                    OtpSend.id == key,
                    OtpSend.status == "reserved",
                )
                .values(status="failed")
            )

    def latest_send_at(self, request_id):
        """When the request's last code was sent, or None."""
        key = request_key(request_id)
        if key is None:
            return None
        with transaction() as session:
            return session.scalar(
                select(func.max(OtpSend.sent_at)).where(
                    OtpSend.otp_request_id == key,
                    OtpSend.status == "sent",
                )
            )

    # Which codes count against a number, a device and an IP.
    def _counted_since(self, session, phone, window_start, rules):
        """Since when the number's codes count (after its last accepted
        code), and whether the asking phone signed in to it before."""
        if rules is None:
            return window_start, False
        since = window_start
        verified = session.scalar(
            select(func.max(OtpRequestRow.verified_at)).where(
                OtpRequestRow.phone_number == phone
            )
        )
        if verified is not None:
            since = max(since, verified)
        return since, self._is_known_phone(session, phone, rules.device_id)

    @staticmethod
    def _phone_times(session, phone, since, known, rules):
        """The number's codes that count: in the window, not failed; for
        the owner's phone only its own, so strangers' codes do not block
        it."""
        counted = select(OtpSend.created_at).join(
            OtpRequestRow,
            OtpRequestRow.id == OtpSend.otp_request_id,
        ).where(
            OtpRequestRow.phone_number == phone,
            OtpSend.status != "failed",
            OtpSend.created_at > since,
        )
        if known:
            counted = counted.where(OtpSend.device_id == rules.device_id)
        return list(session.scalars(counted))

    @staticmethod
    def _is_known_phone(session, phone, device_id):
        """Whether this device already signed in with this number: it asked
        for a code that was accepted."""
        if not device_id:
            return False
        return session.scalar(
            select(OtpSend.id)
            .join(
                OtpRequestRow, OtpRequestRow.id == OtpSend.otp_request_id
            )
            .where(
                OtpRequestRow.phone_number == phone,
                OtpRequestRow.verified_at.is_not(None),
                OtpSend.device_id == device_id,
            )
            .limit(1)
        ) is not None

    @staticmethod
    def _asker_times(session, column, value, start):
        """The times of the counted sends one device or one IP asked for."""
        if not value:
            return []
        return list(
            session.scalars(
                select(OtpSend.created_at).where(
                    column == value,
                    OtpSend.status != "failed",
                    OtpSend.created_at > start,
                )
            )
        )
