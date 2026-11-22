import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/put_off_by_others.dart';
import 'package:app/core/services/reminders/reminder_plan.dart';
import 'package:app/core/services/reminders/reminder_reading.dart';
import 'package:app/core/services/reminders/reminder_sources.dart';
import 'package:app/core/services/reminders/snooze_ledger.dart';
import 'package:app/core/services/reminders/snooze_settling.dart';

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
