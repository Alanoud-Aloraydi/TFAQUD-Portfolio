"""The in-memory store's requests and sends after a send is judged."""

import uuid
from dataclasses import replace
from datetime import datetime

from app.auth.otp_store.records import OtpRequest, OtpSend
from app.auth.otp_store.rules import SendRules


class MemorySends:
    """Opens requests and keeps the state of each send."""

    def _open_request(self, phone: str, now: datetime) -> str:
        """A new request for the number, replacing its open one."""
        for key, request in self._requests.items():
            if request.phone == phone and request.status == "pending":
                self._requests[key] = replace(request, status="superseded")
        request_id = uuid.uuid4().hex
        self._requests[request_id] = OtpRequest(
            id=request_id, phone=phone, created_at=now
        )
        return request_id

    def _reserve(
        self, request_id: str, phone: str, now: datetime, rules: SendRules
    ) -> OtpSend:
        """Reserve the send for the request."""
        send = OtpSend(
            id=uuid.uuid4().hex,
            request_id=request_id,
            phone=phone,
            created_at=now,
            device_id=rules.device_id,
            client_ip=rules.client_ip,
        )
        self._sends[send.id] = send
        return send

    def release_send(self, send_id: str) -> None:
        """Give the reserved place back: the provider refused, so no code left.
        """
        with self._lock:
            send = self._sends.get(send_id)
            if send is not None and send.status == "reserved":
                self._sends[send_id] = replace(send, status="failed")

    def mark_sent(self, send_id, at, expires_at):
        """Mark the send as sent, and keep the request open until the newest
        code's end.
        """
        with self._lock:
            send = self._sends.get(send_id)
            if send is None or send.status != "reserved":
                return
            self._sends[send_id] = replace(send, status="sent", sent_at=at)
            request = self._requests[send.request_id]
            if request.status == "pending":
                expiration = max(request.expires_at or expires_at, expires_at)
                self._requests[request.id] = replace(
                    request, expires_at=expiration
                )

    def latest_send_at(self, request_id: str) -> datetime | None:
        """When the request's last code was sent, or None."""
        with self._lock:
            times = [
                s.sent_at
                for s in self._sends.values()
                if s.request_id == request_id and s.status == "sent"
            ]
            return max(times) if times else None
