import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/reminder_limits.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/services/reminders/snooze_ledger.dart';
import 'package:app/core/services/reminders/task_snooze.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// Takes off the snoozes of the [doses] and [measurements] recorded since,
/// and forgets those that came.
Future<void> settleSnoozes(
  SnoozeLedger ledger,
  PhoneNotifications phone,
  List<(ReminderCircle, DoseOccurrence)> doses,
  List<(ReminderCircle, MeasurementOccurrence)> measurements,
) async {
  await ledger.read();
  final Map<String, SnoozeSlot> snoozed = ledger.entries;
  if (snoozed.isEmpty) return;
  final DateTime now = ledger.now().toUtc();
  final Set<String> recorded = <String>{
    for (final (ReminderCircle circle, DoseOccurrence dose) in doses)
      if (dose.record != null) doseSnoozeKey(circle.id, dose),
    for (final (ReminderCircle circle, MeasurementOccurrence task)
        in measurements)
      if (task.record != null ||
          task.status == MeasurementStatus.read ||
          task.status == MeasurementStatus.skipped)
        measurementSnoozeKey(circle.id, task),
  };
  bool changed = false;
  for (final String key in snoozed.keys.toList()) {
    final SnoozeSlot entry = snoozed[key]!;
    if (recorded.contains(key)) {
      await phone.cancel(cardSnoozeIdBase + entry.slot);
    } else if (entry.snooze.at.isAfter(now)) {
      continue;
    }
    snoozed.remove(key);
    changed = true;
  }
  if (changed) await ledger.save();
}
