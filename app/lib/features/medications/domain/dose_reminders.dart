import 'dart:async';

import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';

export 'package:app/core/services/reminder_circle.dart';

/// The words of the reminders. They are given from outside, so this file
/// needs no translations and the tests can use plain words.
class DoseReminderTexts {
  const DoseReminderTexts({
    required this.title,
    required this.body,
    required this.keepTitle,
    required this.keepBody,
  });

  /// «حان موعد دواء أمي نورة».
  final String Function(ReminderCircle circle) title;

  /// The medicine's name, «ميتفورمين».
  final String Function(DoseOccurrence dose) body;

  /// The last note: open the app so the reminders go on.
  final String Function() keepTitle;
  final String Function() keepBody;
}

/// What a reminder's payload starts with; the circle's id follows.
const String doseReminderPayload = 'dose:';

/// The payload of the note after the last reminder.
const String keepRemindersPayload = 'reminders:keep';

/// iOS keeps at most 64 scheduled notifications for an app (the 64 set
/// last). The reminders take [maxDoseReminders] of them, and the note after
/// them one more.
const int maxDoseReminders = 60;

/// The ids of the reminders: [reminderIdBase] to [reminderIdBase] + 60.
const int reminderIdBase = 7000;

/// Whether a scheduled notification is one of the reminders.
bool isReminderPayload(String payload) =>
    payload.startsWith(doseReminderPayload) || payload == keepRemindersPayload;

/// What a simplified-mode "لاحقا" snooze's payload starts with; the
/// circle's id follows, the same as [doseReminderPayload]. A separate
/// prefix and id so [DoseReminders]'s own replace cycle never cancels it
/// as an orphaned reminder.
const String doseSnoozePayload = 'dose-snooze:';

/// The one slot a snooze uses; a new snooze replaces any pending one.
const int doseSnoozeId = reminderIdBase + maxDoseReminders + 10;

/// The moment a dose is due. The server keeps the day and the time in Riyadh
/// (UTC+3, no daylight saving), so this is the same moment on any phone.
DateTime doseMoment(DoseOccurrence dose) {
  final List<String> parts = dose.time.split(':');
  return DateTime.utc(
    dose.scheduledOn.year,
    dose.scheduledOn.month,
    dose.scheduledOn.day,
    int.parse(parts[0]) - 3,
    int.parse(parts[1]),
  );
}

/// The reminders for [doses] after [now]: one at each dose that is not
/// recorded yet (taken or skipped), the nearest first, at most
/// [maxDoseReminders]. After the last one comes a note to open the app, which
/// fires only when the app was not opened in all that time (each opening
/// sets the reminders again, further on).
List<ScheduledNotification> planDoseReminders({
  required List<(ReminderCircle, DoseOccurrence)> doses,
  required DateTime now,
  required DoseReminderTexts texts,
}) {
  // A dose in the next minute is too close to set: by the time the phone
  // has it, the moment may have passed.
  final DateTime earliest = now.toUtc().add(const Duration(minutes: 1));
  final List<(DateTime, ReminderCircle, DoseOccurrence)> upcoming =
      <(DateTime, ReminderCircle, DoseOccurrence)>[
        for (final (ReminderCircle circle, DoseOccurrence dose) in doses)
          if (dose.record == null && doseMoment(dose).isAfter(earliest))
            (doseMoment(dose), circle, dose),
      ]..sort(
        (
          (DateTime, ReminderCircle, DoseOccurrence) a,
          (DateTime, ReminderCircle, DoseOccurrence) b,
        ) => a.$1.compareTo(b.$1),
      );
  final List<(DateTime, ReminderCircle, DoseOccurrence)> kept = upcoming
      .take(maxDoseReminders)
      .toList();
  return <ScheduledNotification>[
    for (int i = 0; i < kept.length; i++)
      ScheduledNotification(
        id: reminderIdBase + i,
        at: kept[i].$1,
        title: texts.title(kept[i].$2),
        body: texts.body(kept[i].$3),
        payload: '$doseReminderPayload${kept[i].$2.id}',
        thread: kept[i].$2.id,
      ),
    if (kept.isNotEmpty)
      ScheduledNotification(
        id: reminderIdBase + maxDoseReminders,
        at: kept.last.$1.add(const Duration(minutes: 1)),
        title: texts.keepTitle(),
        body: texts.keepBody(),
        payload: keepRemindersPayload,
      ),
  ];
}

/// Keeps a reminder on the phone at each dose time of every circle of the
/// signed-in person, for the coming week.
///
/// The phone shows them even when the app is closed, so they work without a
/// server push. They are set again when the home data loads
/// ([sync]), when the app comes back to the front ([refresh]), and after
/// each change of a medicine or a dose record anywhere in the app (the
/// [MedicationsUseCase.changes]): a recorded dose loses its reminder. On
/// sign-out [clear] removes them all.
class DoseReminders {
  DoseReminders(
    this._medications,
    this._phone, {
    required this.texts,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now {
    // Kept for the life of the app, as this object is.
    _medications.changes.listen((_) => unawaited(refresh()));
  }

  final MedicationsUseCase _medications;
  final PhoneNotifications _phone;

  /// The words of the reminders.
  final DoseReminderTexts texts;
  final DateTime Function() _now;

  /// How many days are read ahead. A week is enough while the app is opened
  /// now and then, and stays well under the 31 days the server gives at once.
  static const int days = 7;

  List<ReminderCircle> _circles = const <ReminderCircle>[];
  Future<void>? _running;
  bool _again = false;
  bool _asked = false;

  /// Goes up at each [clear], so a reading that ends after a sign-out sets
  /// nothing.
  int _session = 0;

  /// Reminds of the doses of [circles] from now on. Called when the home
  /// data loads with the person's circles.
  Future<void> sync(List<ReminderCircle> circles) {
    _circles = List<ReminderCircle>.unmodifiable(circles);
    return refresh();
  }

  /// Reads the doses again and sets the reminders. One reading runs at a
  /// time; a call during it makes one more reading right after.
  Future<void> refresh() {
    final Future<void>? running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    final Future<void> run = _run().whenComplete(() {
      _running = null;
      if (_again) {
        _again = false;
        unawaited(refresh());
      }
    });
    _running = run;
    return run;
  }

  /// Reschedules one dose's own reminder [after] from now — the simplified
  /// mode's "لاحقا". Local-only: no plan or record changes, so nothing to
  /// undo if the app is never reopened before it fires.
  Future<void> snooze({
    required String circleId,
    required String title,
    required String body,
    required Duration after,
  }) => _phone.schedule(
    ScheduledNotification(
      id: doseSnoozeId,
      at: DateTime.now().toUtc().add(after),
      title: title,
      body: body,
      payload: '$doseSnoozePayload$circleId',
    ),
  );

  /// Cancels a pending snooze: the dose it was for got taken another way.
  Future<void> cancelSnooze() => _phone.cancel(doseSnoozeId);

  /// Removes every reminder: the person signed out, or the sign-in ended.
  Future<void> clear() async {
    _session++;
    _circles = const <ReminderCircle>[];
    _again = false;
    await _phone.cancelAll();
  }

  Future<void> _run() async {
    final int session = _session;
    final List<ReminderCircle> circles = _circles;
    if (circles.isEmpty) {
      await _replace(const <ScheduledNotification>[], session);
      return;
    }
    final DateTime now = _now();
    final DateTime riyadh = riyadhNow(now);
    final DateTime from = DateTime.utc(riyadh.year, riyadh.month, riyadh.day);
    final DateTime to = from.add(const Duration(days: days - 1));
    final List<(ReminderCircle, DoseOccurrence)> doses =
        <(ReminderCircle, DoseOccurrence)>[];
    for (final ReminderCircle circle in circles) {
      final result = await _medications.getOccurrences(circle.id, from, to);
      if (session != _session) return;
      final List<DoseOccurrence>? list = result.tryGetSuccess();
      // Offline or refused: the reminders already set stay until the next
      // reading.
      if (list == null) return;
      for (final DoseOccurrence dose in list) {
        doses.add((circle, dose));
      }
    }
    final List<ScheduledNotification> planned = planDoseReminders(
      doses: doses,
      now: now,
      texts: texts,
    );
    // The question comes when there is something to remind of, once per run
    // of the app; iOS shows it only the first time.
    if (planned.isNotEmpty && !_asked) {
      _asked = true;
      await _phone.requestPermission();
      if (session != _session) return;
    }
    await _replace(planned, session);
  }

  /// Takes off the reminders that are no longer planned and sets the
  /// planned ones (a reminder with the same id is replaced).
  Future<void> _replace(
    List<ScheduledNotification> planned,
    int session,
  ) async {
    final Set<int> keep = <int>{
      for (final ScheduledNotification notification in planned) notification.id,
    };
    final Map<int, String> pending = await _phone.pending();
    for (final MapEntry<int, String> entry in pending.entries) {
      if (session != _session) return;
      if (isReminderPayload(entry.value) && !keep.contains(entry.key)) {
        await _phone.cancel(entry.key);
      }
    }
    for (final ScheduledNotification notification in planned) {
      if (session != _session) return;
      await _phone.schedule(notification);
    }
  }
}
