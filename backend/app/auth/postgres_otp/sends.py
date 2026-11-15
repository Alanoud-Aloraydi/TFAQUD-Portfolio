"""The PostgreSQL store's sends after one is judged."""

from uuid import uuid4

from sqlalchemy import func, select, update

from app.auth.postgres_otp.keys import request_key
from app.database import transaction
from app.models import OtpRequest as OtpRequestRow
from app.models import OtpSend


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
