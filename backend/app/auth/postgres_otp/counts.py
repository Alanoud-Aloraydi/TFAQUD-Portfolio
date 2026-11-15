"""The PostgreSQL store's counting of the codes a send is judged by."""

from sqlalchemy import func, select

from app.models import OtpRequest as OtpRequestRow
from app.models import OtpSend


class PostgresSendCounts:
    """Which codes count against a number, a device and an IP."""

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
