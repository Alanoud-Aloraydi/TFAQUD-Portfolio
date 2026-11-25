import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/reminders/reminder_plan.dart';
import 'package:app/app/services/reminders/reminder_reading.dart';
import 'package:app/app/services/reminders/reminders_enabled.dart';
import 'package:app/app/services/reminders/snooze_ledger.dart';
import 'package:app/app/services/reminders/snooze_reminder.dart';
import 'package:app/app/services/reminders/snooze_settling.dart';
import 'package:app/core/reminders/reminder_payloads.dart';
import 'package:app/core/reminders/shared_snooze.dart';
import 'package:app/core/reminders/task_snooze.dart';
import 'package:app/core/utils/coalescing_runner.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// Reads the tasks of the circles and sets the planned reminders on the
/// phone, one reading at a time; none while the server sends them.
class ReminderSync {
  ReminderSync({
    required this.sources,
    required this.phone,
    required this.permission,
    required this.ledger,
    required this.enabled,
    required this.texts,
    required this.fromServer,
  });

  final ReminderSources sources;
  final PhoneNotifications phone;
  final ReminderPermission permission;
  final SnoozeLedger ledger;
  final RemindersEnabled enabled;
  final DoseReminderTexts texts;
  final bool Function() fromServer;

  /// The circles being reminded of.
  List<ReminderCircle> circles = const <ReminderCircle>[];
  late final CoalescingRunner _runner = CoalescingRunner(_run);
  bool _asked = false;

  /// Goes up at each [clear]: a reading that ends after it sets nothing.
  int _session = 0;

  /// Reminds of the doses of [circles] from now on.
  Future<void> sync(List<ReminderCircle> circles) {
    this.circles = List<ReminderCircle>.unmodifiable(circles);
    return refresh();
  }

  /// Reads the doses again and sets the reminders. One reading runs at a
  /// time; a call during it makes one more reading right after.
  Future<void> refresh() => _runner.run();

  /// Removes every reminder: the person signed out, or the sign-in ended.
  Future<void> clear() async {
    _session++;
    circles = const <ReminderCircle>[];
    _runner.dropPending();
    await phone.cancelAll();
    await ledger.drop();
  }

  Future<void> _run() async {
    final int session = _session;
    bool stale() => session != _session;
    if (!enabled.on.value) {
      // Off in the app: nothing more comes, a task put off included.
      await phone.cancelAll();
      return ledger.drop();
    }
    final List<ScheduledNotification>? planned = circles.isEmpty
        ? const <ScheduledNotification>[]
        : await readAndPlan(
            circles: circles,
            sources: sources,
            phone: phone,
            ledger: ledger,
            texts: texts,
            stale: stale,
            fromServer: fromServer(),
          );
    if (planned == null) return;
    // The question comes when there is something to remind of, once per run
    // of the app; iOS shows it only the first time.
    if (planned.isNotEmpty) {
      final bool first = !_asked;
      _asked = true;
      await permission.ask(request: first);
      if (stale()) return;
    }
    await replaceReminders(phone, planned, stale);
  }
}

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
