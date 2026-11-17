"""Small rules of Arabic for the push messages: «ال» before a medicine's
name, and «لـ» before a visit's."""


def with_article(name: str | None) -> str:
    """«البتراترا» for «بتراترا», as the app says a medicine (`withArticle`
    in arabic_names.dart). A name with «ال» already, or not written in
    Arabic letters («Panadol»), stays as it is."""
    value = (name or "").strip()
    if not value or value.startswith("ال"):
        return value
    return f"ال{value}" if _arabic(value[0]) else value


# Visits that read better known («موعد خالد للطوارئ», not «لطوارئ»).
_KNOWN_VISITS = {"طوارئ": "للطوارئ", "أسنان": "للأسنان", "أشعة": "للأشعة"}


def for_visit(visit: str | None) -> str:
    """«لجلسة علاج», «للتطعيم» for a name with «ال» (the «ال» joins «لـ» as
    «لل»), «لـMRI» for one in other letters; empty without a name."""
    value = (visit or "").strip()
    if not value:
        return ""
    if value in _KNOWN_VISITS:
        return _KNOWN_VISITS[value]
    if value.startswith("ال"):
        return f"لل{value[2:]}"
    return f"ل{value}" if _arabic(value[0]) else f"لـ{value}"


def _arabic(letter: str) -> bool:
    """Whether `letter` is one of the Arabic letters, hamza to yeh."""
    return "ء" <= letter <= "ي"
