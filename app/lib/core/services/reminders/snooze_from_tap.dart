import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/services/reminders/snooze_putter.dart';
import 'package:app/core/services/reminders/task_snooze.dart';

/// «ذكّرني لاحقًا» from a notification: [tap] is the snooze action of a
/// reminder, which carries its words and its task; that task comes again
/// in [notificationSnooze], as from its card. False when the tap is not a
/// snoozable reminder.
Future<bool> snoozeFromTap(
  SnoozePutter putter,
  DateTime Function() now,
  String tap,
) async {
  if (!isSnoozeTap(tap)) return false;
  final String payload = tap.substring(snoozeTapPrefix.length);
  final String? circleId = reminderCircleId(payload);
  final (String, String)? text = reminderText(payload);
  final (String, String)? target = snoozeTarget(payload);
  if (circleId == null || text == null || target == null) return false;
  await putter.put(
    key: target.$1,
    after: notificationSnooze,
    snooze: TaskSnooze(
      circleId: circleId,
      task: SnoozedTask.of(payload),
      subject: target.$2,
      at: now().toUtc().add(notificationSnooze),
    ),
    title: text.$1,
    body: text.$2,
  );
  return true;
}
