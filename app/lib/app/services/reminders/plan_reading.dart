import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/reminders/own_snoozes.dart';
import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/app/services/reminders/reminder_plan.dart';
import 'package:app/app/services/reminders/reminder_reading.dart';
import 'package:app/app/services/reminders/snooze_ledger.dart';
import 'package:app/app/services/reminders/snooze_settling.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// Reads the tasks of [circles] and plans the reminders to set, with the
/// slots of the tasks put off taken out of the room they have. Null when a
/// reading failed or [stale] says the run is over.
///
/// [fromServer]: the server sends this phone the reminders at the tasks'
/// times (ServerReminders), so none is planned here; the tasks are still
/// read, so a task put off from this phone and recorded meanwhile loses
/// its reminder.
Future<List<ScheduledNotification>?> readAndPlan({
  required List<ReminderCircle> circles,
  required ReminderSources sources,
  required PhoneNotifications phone,
  required SnoozeLedger ledger,
  required DoseReminderTexts texts,
  required bool Function() stale,
  bool fromServer = false,
}) async {
  final ReminderReading? reading = await readReminders(
    circles: circles,
    now: ledger.now(),
    sources: sources,
    stale: stale,
  );
  if (reading == null) return null;
  await settleSnoozes(ledger, phone, reading.doses, reading.measurements);
  if (stale()) return null;
  // Whoever reminds of the rest, a task put off from this account is
  // reminded of by this phone; one whose reminder it lost is set again.
  await restoreOwnSnoozes(ledger, phone, reading, texts);
  if (fromServer) return const <ScheduledNotification>[];
  return planDoseReminders(
    doses: reading.doses,
    measurements: reading.measurements,
    appointments: reading.appointments,
    // The time after the readings, which can take a while on a slow
    // network: a dose that came close meanwhile is not set too late.
    now: ledger.now(),
    texts: texts,
    until: reading.until,
    // The tasks put off have their own slots, and their reminders wait
    // for the new time; one put off by someone else is reminded of by
    // the server then.
    limit: maxDoseReminders - ledger.entries.length,
    snoozed: <String>{
      ...ledger.entries.keys,
      ...putOffByOthers(reading.doses, reading.measurements, ledger.now()),
    },
  );
}

/// The keys of the tasks someone else in the circle put off, still
/// waiting: the server reminds this phone of them at the new time.
Set<String> putOffByOthers(
  List<(ReminderCircle, DoseOccurrence)> doses,
  List<(ReminderCircle, MeasurementOccurrence)> measurements,
  DateTime now,
) => <String>{
  for (final (ReminderCircle circle, DoseOccurrence dose) in doses)
    if (dose.snooze?.waitsAt(now) ?? false) doseSnoozeKey(circle.id, dose),
  for (final (ReminderCircle circle, MeasurementOccurrence task)
      in measurements)
    if (task.snooze?.waitsAt(now) ?? false)
      measurementSnoozeKey(circle.id, task),
};

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
