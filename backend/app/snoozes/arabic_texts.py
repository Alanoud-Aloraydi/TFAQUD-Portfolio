"""Arabic counts of minutes and hours, and a wall time as the app
shows it."""

from datetime import time


def minutes_text(minutes: int) -> str:
    """«دقيقة», «دقيقتين», «5 دقائق», «15 دقيقة», «ساعة», «ساعتين»,
    «3 ساعات», «11 ساعة», «ساعة و30 دقيقة»: the Arabic count of a time put
    off (up to 12 hours)."""
    hours, rest = divmod(minutes, 60)
    if hours == 0:
        return _count(rest, "دقيقة", "دقيقتين", "دقائق")
    whole = _count(hours, "ساعة", "ساعتين", "ساعات")
    if rest == 0:
        return whole
    return f"{whole} و{_count(rest, 'دقيقة', 'دقيقتين', 'دقائق')}"


def _count(number: int, one: str, two: str, few: str) -> str:
    """An Arabic count: «ساعة», «ساعتين», «3 ساعات», «11 ساعة»."""
    if number == 1:
        return one
    if number == 2:
        return two
    if number <= 10:
        return f"{number} {few}"
    return f"{number} {one}"


def clock_text(moment: time) -> str:
    """«8:00 ص», «5:45 م»: a wall time as the app shows it."""
    hour = moment.hour % 12 or 12
    half = "ص" if moment.hour < 12 else "م"
    return f"{hour}:{moment.minute:02d} {half}"
