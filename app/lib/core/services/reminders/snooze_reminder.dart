import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/reminder_limits.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/services/reminders/task_snooze.dart';

/// Sets the reminder of the task of [key], put off to [snooze]'s moment,
/// in its [slot] of the tasks put off, with the words [title] and [body].
/// It can be put off again, the same as the reminder it came from.
Future<void> setSnoozeReminder(
  PhoneNotifications phone, {
  required String key,
  required int slot,
  required TaskSnooze snooze,
  required String title,
  required String body,
}) => phone.schedule(
  ScheduledNotification(
    id: cardSnoozeIdBase + slot,
    at: snooze.at,
    title: title,
    body: body,
    payload: payloadWithText(
      '${snooze.task.payloadPrefix}${snooze.circleId}',
      title,
      body,
      snoozeKey: key,
      subject: snooze.subject,
    ),
    thread: snooze.circleId,
    snoozable: true,
  ),
);
