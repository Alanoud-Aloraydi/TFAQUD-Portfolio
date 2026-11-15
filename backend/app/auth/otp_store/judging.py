"""Judging a send against every limit, and when the next may come."""

from datetime import datetime, timedelta

from app.auth.otp_store.rules import SendRules


def judge_send(
    now: datetime,
    phone_times: list[datetime],
    window: timedelta,
    max_sends: int,
    rules: SendRules,
    device_times: list[datetime] = (),
    ip_times: list[datetime] = (),
) -> tuple[datetime | None, str | None]:
    """When the next send must wait, and why; (None, None) when it may go.

    `phone_times` are the number's counted sends in `window`; `device_times`
    and `ip_times` the asker's in `rules.requester_window`.
    """
    # The number's cap: back when its oldest counted code leaves the window.
    phone_times = sorted(phone_times)
    if len(phone_times) >= max_sends:
        return phone_times[len(phone_times) - max_sends] + window, "phone"
    # The wait after the last code, longer with each code.
    if rules.waits and phone_times:
        wait = rules.waits[min(len(phone_times), len(rules.waits)) - 1]
        ready = phone_times[-1] + timedelta(seconds=wait)
        if now < ready:
            return ready, "wait"
    # The asking device's and IP's caps for the hour.
    for times, cap, reason in (
        (device_times, rules.max_device_sends, "device"),
        (ip_times, rules.max_ip_sends, "ip"),
    ):
        if cap is not None and len(times) >= cap:
            times = sorted(times)
            return times[len(times) - cap] + rules.requester_window, reason
    return None, None


def next_send_at(
    now: datetime,
    phone_times: list[datetime],
    window: timedelta,
    max_sends: int,
    rules: SendRules,
) -> datetime:
    """After a send at `now`, the first moment the number may get another."""
    times = sorted([*phone_times, now])
    if len(times) >= max_sends:
        return times[len(times) - max_sends] + window
    if rules.waits:
        wait = rules.waits[min(len(times), len(rules.waits)) - 1]
        return now + timedelta(seconds=wait)
    return now
