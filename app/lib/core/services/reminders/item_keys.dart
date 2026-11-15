/// The keys that name the one item a notification is about, the same for
/// the phone's own reminders and the server's pushes, so one way of opening
/// serves both. A dose and a reading are named by their snooze key
/// (`doseSnoozeKey`, `measurementSnoozeKey`), a visit by
/// [appointmentItemKey]; each of these starts with its circle's id. An
/// entry of the bell is [inboxItemKey] (still to answer) or
/// [answeredItemKey] (in «السابقة»).
library;

/// Between an appointment reminder's circle and its appointment's id, in
/// the reminder's payload.
const String appointmentIdMark = '@';

const String _inbox = 'inbox|';
const String _answered = 'answered|';

/// A visit of [circleId]'s «اليوم».
String appointmentItemKey(String circleId, String appointmentId) =>
    '$circleId|appointment|$appointmentId';

/// An invitation or a request that waits for an answer on the bell.
String inboxItemKey(String id) => '$_inbox$id';

/// A request whose answer is in the bell's «السابقة».
String answeredItemKey(String id) => '$_answered$id';

/// Whether [key] is an entry of the bell's «السابقة».
bool isAnsweredItem(String? key) => key?.startsWith(_answered) ?? false;

/// The circle whose «اليوم» holds the item [key]; null for the bell.
String? itemCircleId(String? key) =>
    key == null || key.startsWith(_inbox) || key.startsWith(_answered)
    ? null
    : key.split('|').first;
