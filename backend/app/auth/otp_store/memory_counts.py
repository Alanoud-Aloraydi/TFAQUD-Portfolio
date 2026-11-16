"""The in-memory store's counting of the codes a send is judged by."""

from datetime import datetime

from app.auth.otp_store.records import AttemptsExhausted
from app.auth.otp_store.rules import SendRules


class MemorySendCounts:
    """Which codes count against a number, a device and an IP."""

    def _check_resend(
        self, request_id: str, phone: str, max_tries: int | None
    ) -> None:
        """A resend: the request must be this number's, still open, and have
        tries left."""
        request = self._requests.get(request_id)
        if (
            request is None
            or request.phone != phone
            or request.status != "pending"
        ):
            raise KeyError(request_id)
        if max_tries is not None and request.wrong_tries >= max_tries:
            raise AttemptsExhausted()

    def _counted_since(
        self, phone: str, window_start: datetime, rules: SendRules | None
    ) -> tuple[datetime, bool]:
        """Since when the number's codes count, and whether the asking phone
        signed in to it before. The codes count only after the number's last
        accepted code; a phone that signed in to it before (its device)
        counts only its own codes."""
        if rules is None:
            return window_start, False
        since = window_start
        verified = [
            r.verified_at
            for r in self._requests.values()
            if r.phone == phone and r.verified_at is not None
        ]
        if verified:
            since = max(since, max(verified))
        known = bool(rules.device_id) and any(
            s.phone == phone
            and s.device_id == rules.device_id
            and self._requests[s.request_id].verified_at is not None
            for s in self._sends.values()
        )
        return since, known

    def _phone_times(
        self, phone: str, since: datetime, known: bool, rules: SendRules
    ) -> list[datetime]:
        """The number's codes that count: in the window, not failed."""
        return [
            s.created_at
            for s in self._sends.values()
            if s.phone == phone
            and s.created_at > since
            and s.status != "failed"
            and (not known or s.device_id == rules.device_id)
        ]

    def _requester_times(
        self, now: datetime, rules: SendRules | None, known: bool
    ) -> tuple[list[datetime], list[datetime]]:
        """The asking device's and IP's codes in the last hour, for any
        number (no IP cap for a known phone)."""
        device_times: list[datetime] = []
        ip_times: list[datetime] = []
        if rules is None:
            return device_times, ip_times
        start = now - rules.requester_window
        live = [
            s
            for s in self._sends.values()
            if s.created_at > start and s.status != "failed"
        ]
        if rules.device_id:
            device_times = [
                s.created_at for s in live if s.device_id == rules.device_id
            ]
        if rules.client_ip and not known:
            ip_times = [
                s.created_at for s in live if s.client_ip == rules.client_ip
            ]
        return device_times, ip_times
