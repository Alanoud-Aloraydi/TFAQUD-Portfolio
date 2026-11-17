/// Whether [a] and [b] are the same account. The server writes an
/// account's id with its UUID's dashes in some answers (a visit's
/// companions, a circle's members) and without them in others (the
/// signed-in account on «الرئيسية»), so the ids are compared without them.
bool sameAccount(String? a, String? b) =>
    a != null && b != null && _bare(a) == _bare(b);

String _bare(String id) => id.replaceAll('-', '').toLowerCase();
