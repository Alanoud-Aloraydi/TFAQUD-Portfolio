import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/reminders/dose_reminder_texts.dart';
import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/app/services/reminders/reminder_reading.dart';
import 'package:app/app/services/reminders/shared_snooze.dart';
import 'package:app/app/services/reminders/snooze_ledger.dart';
import 'package:app/app/services/reminders/snooze_reminder.dart';
import 'package:app/app/services/reminders/task_snooze.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// Sets again the reminders of the tasks the person on this phone put off,
/// still waiting on the server, that this phone no longer has: the
/// notifications were turned off and on again, or the person signed in
/// again. The server reminds everyone else at that time, never the one
/// who put it off, so without this nothing would come.
Future<void> restoreOwnSnoozes(
  SnoozeLedger ledger,
  PhoneNotifications phone,
  ReminderReading reading,
  DoseReminderTexts texts,
) async {
  await ledger.read();
  final DateTime now = ledger.now();
  final List<(String, TaskSnooze, String, String)>
  own = <(String, TaskSnooze, String, String)>[
    for (final (ReminderCircle circle, DoseOccurrence dose) in reading.doses)
      if (dose.record == null && ownWaitingSnooze(circle, dose.snooze, now))
        (
          doseSnoozeKey(circle.id, dose),
          taskSnoozeOf(circle, SnoozedTask.dose, dose.name, dose.snooze!),
          texts.title(circle, dose),
          texts.body(circle, dose),
        ),
    for (final (ReminderCircle circle, MeasurementOccurrence task)
        in reading.measurements)
      if (measurementOpen(task) && ownWaitingSnooze(circle, task.snooze, now))
        (
          measurementSnoozeKey(circle.id, task),
          taskSnoozeOf(
            circle,
            SnoozedTask.measurement,
            task.kind.name,
            task.snooze!,
          ),
          texts.measurementTitle(circle),
          texts.measurementBody(circle, task),
        ),
  ];
  bool changed = false;
  for (final (String key, TaskSnooze snooze, String title, String body)
      in own) {
    if (ledger.entries.containsKey(key)) continue;
    final int slot = ledger.freeSlot();
    ledger.entries[key] = (snooze: snooze, slot: slot);
    await setSnoozeReminder(
      phone,
      key: key,
      slot: slot,
      snooze: snooze,
      title: title,
      body: body,
    );
    changed = true;
  }
  if (changed) await ledger.save();
}

/// Not recorded yet: a reading done or skipped is reminded of no more.
bool measurementOpen(MeasurementOccurrence task) =>
    task.record == null &&
    task.status != MeasurementStatus.read &&
    task.status != MeasurementStatus.skipped;

/// Put off by the person on this phone, and still waiting.
bool ownWaitingSnooze(
  ReminderCircle circle,
  SharedSnooze? shared,
  DateTime now,
) =>
    shared != null &&
    circle.viewerId != null &&
    shared.byAccountId == circle.viewerId &&
    shared.waitsAt(now);

/// The snooze this phone keeps for a task the server has put off.
TaskSnooze taskSnoozeOf(
  ReminderCircle circle,
  SnoozedTask task,
  String subject,
  SharedSnooze shared,
) => TaskSnooze(
  circleId: circle.id,
  task: task,
  subject: subject,
  at: shared.remindAt.toUtc(),
);
