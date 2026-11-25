import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/push_target.dart';
import 'package:app/app/services/reminders/reminder_payload_parts.dart';
import 'package:app/core/reminders/item_keys.dart';
import 'package:app/core/reminders/reminder_payloads.dart';

/// The key of the item a tapped notification is about (item_keys.dart): a
/// push's from its data, a dose's or a reading's reminder by its snooze
/// key, a visit's by the id after its circle; null for the note to open
/// the app and for an older reminder that names no item.
String? tappedItemKey(String tap) {
  if (pushKind(tap) != null) return pushTapItem(tap);
  if (snoozeTarget(tap) case (final String key, _)) return key;
  if (!tap.startsWith(appointmentReminderPayload)) return null;
  final List<String> parts = tap
      .substring(appointmentReminderPayload.length)
      .split(appointmentIdMark);
  return parts.length == 2 ? appointmentItemKey(parts[0], parts[1]) : null;
}
