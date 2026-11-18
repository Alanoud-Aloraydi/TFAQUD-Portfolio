import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';

/// Takes off the reminders that are no longer [planned] and sets the
/// planned ones (a reminder with the same id is replaced). It stops when
/// [stale] says the run is over.
Future<void> replaceReminders(
  PhoneNotifications phone,
  List<ScheduledNotification> planned,
  bool Function() stale,
) async {
  final Set<int> keep = <int>{
    for (final ScheduledNotification notification in planned) notification.id,
  };
  final Map<int, String> pending = await phone.pending();
  for (final MapEntry<int, String> entry in pending.entries) {
    if (stale()) return;
    if (isReminderPayload(entry.value) && !keep.contains(entry.key)) {
      await phone.cancel(entry.key);
    }
  }
  for (final ScheduledNotification notification in planned) {
    if (stale()) return;
    await phone.schedule(notification);
  }
}
