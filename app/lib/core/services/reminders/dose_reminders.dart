import 'dart:async';
import 'dart:convert';

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/services/reminders/reminder_plan.dart';
import 'package:app/core/utils/coalescing_runner.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:app/core/services/reminder_circle.dart';
export 'package:app/core/services/reminders/reminder_payloads.dart';
export 'package:app/core/services/reminders/reminder_plan.dart';

/// The slots of the doses and measurements put off («ذكّرني لاحقًا» on a
/// card, a full-screen reminder or a notification, in either mode), after
/// the note's: each task has its own, so two tasks put off both come again.
const int cardSnoozeIdBase = reminderIdBase + maxDoseReminders + 1;

/// At most this many tasks put off at once. The reminders to come give up
/// as many places, so the phone's 64 are never passed.
const int maxCardSnoozes = 5;

/// A dose or measurement put off with «ذكّرني لاحقًا»: its circle, which
/// kind of task, its [subject] (the medicine's name, or the
/// [MeasurementKind]'s name) and the moment [at] it is reminded of again.
/// The cards of both modes show the time; the calendar copy moves to it.
class TaskSnooze extends Equatable {
  const TaskSnooze({
    required this.circleId,
    required this.task,
    required this.subject,
    required this.at,
  });

  final String circleId;
  final SnoozedTask task;
  final String subject;

  /// In UTC.
  final DateTime at;

  @override
  List<Object?> get props => [circleId, task, subject, at];
}

/// A task put off, and the slot of its reminder.
typedef _Snoozed = ({TaskSnooze snooze, int slot});

/// Keeps the reminders of every circle of the signed-in person on the
/// phone, for the coming week: each dose time, each measurement time, and
/// each appointment (a day before, and shortly before). The name stays from
/// when it reminded of doses only.
///
/// The phone shows them even when the app is closed, so they work without a
/// server push; the server only tells of a dose or measurement that was
/// missed. They are set again when the home data loads ([sync]), when the
/// app comes back to the front ([refresh]), and after each change of a
/// medicine, a dose record, a measurement plan or reading, or an
/// appointment anywhere in the app: a recorded dose or measurement, and a
/// cancelled appointment, lose their reminders. On sign-out [clear] removes
/// them all.
///
/// Without [measurements] or [appointments] (the tests of doses), only the
/// doses are read.
class DoseReminders {
  DoseReminders(
    this._medications,
    this._phone, {
    required this.texts,
    MeasurementRepository? measurements,
    AppointmentRepository? appointments,
    DateTime Function()? clock,
  }) : _measurements = measurements,
       _appointments = appointments,
       _now = clock ?? DateTime.now {
    // Kept for the life of the app, as this object is.
    _medications.changes.listen((_) => unawaited(refresh()));
    measurements?.changes.listen((_) => unawaited(refresh()));
    measurements?.recorded.listen((_) => unawaited(refresh()));
    appointments?.changes.listen((_) => unawaited(refresh()));
  }

  final MedicationsUseCase _medications;
  final MeasurementRepository? _measurements;
  final AppointmentRepository? _appointments;
  final PhoneNotifications _phone;

  /// The words of the reminders.
  final DoseReminderTexts texts;
  final DateTime Function() _now;

  /// How many days are read ahead. A week is enough while the app is opened
  /// now and then, and stays well under the 31 days the server gives at once.
  static const int days = 7;

  List<ReminderCircle> _circles = const <ReminderCircle>[];
  late final CoalescingRunner _runner = CoalescingRunner(_run);
  bool _asked = false;

  /// Goes up at each [clear], so a reading that ends after a sign-out sets
  /// nothing.
  int _session = 0;

  static const String _snoozesKey = 'dose_card_snoozes';

  /// The tasks put off, by [doseSnoozeKey] or [measurementSnoozeKey], the
  /// first put off first. Kept on the phone, so a card still shows its time
  /// after the app is opened again.
  final Map<String, _Snoozed> _snoozed = <String, _Snoozed>{};
  Future<void>? _snoozesRead;
  final ValueNotifier<Map<String, TaskSnooze>> _published =
      ValueNotifier<Map<String, TaskSnooze>>(const <String, TaskSnooze>{});
  Timer? _snoozeEnds;

  /// The tasks put off and not yet reminded of again, by their keys: the
  /// cards of both modes show «بنذكّرك 2:36 م», and the calendar copy has
  /// an event at that time.
  ValueListenable<Map<String, TaskSnooze>> get snoozes {
    unawaited(_readSnoozes());
    return _published;
  }

  /// Reminds of the doses of [circles] from now on. Called when the home
  /// data loads with the person's circles.
  Future<void> sync(List<ReminderCircle> circles) {
    _circles = List<ReminderCircle>.unmodifiable(circles);
    return refresh();
  }

  /// Reads the doses again and sets the reminders. One reading runs at a
  /// time; a call during it makes one more reading right after.
  Future<void> refresh() => _runner.run();

  /// «ذكّرني لاحقًا» on [dose] of [circleId], in either mode: its reminder
  /// again [after] from now, with the words of its own reminder.
  Future<void> snoozeDose(
    String circleId,
    DoseOccurrence dose,
    Duration after,
  ) {
    final ReminderCircle circle = _circleOf(circleId);
    return _snooze(
      key: doseSnoozeKey(circleId, dose),
      snooze: TaskSnooze(
        circleId: circleId,
        task: SnoozedTask.dose,
        subject: dose.name,
        at: _now().toUtc().add(after),
      ),
      title: texts.title(circle, dose),
      body: texts.body(circle, dose),
    );
  }

  /// The same for a measurement [task].
  Future<void> snoozeMeasurement(
    String circleId,
    MeasurementOccurrence task,
    Duration after,
  ) {
    final ReminderCircle circle = _circleOf(circleId);
    return _snooze(
      key: measurementSnoozeKey(circleId, task),
      snooze: TaskSnooze(
        circleId: circleId,
        task: SnoozedTask.measurement,
        subject: task.kind.name,
        at: _now().toUtc().add(after),
      ),
      title: texts.measurementTitle(circle),
      body: texts.measurementBody(circle, task),
    );
  }

  /// «ذكّرني لاحقًا» from a notification: [tap] is the snooze action of a
  /// reminder, which carries its words and its task; that task comes again
  /// in [notificationSnooze], as from its card. False when the tap is not a
  /// snoozable reminder.
  Future<bool> snoozeTap(String tap) async {
    if (!isSnoozeTap(tap)) return false;
    final String payload = tap.substring(snoozeTapPrefix.length);
    final String? circleId = reminderCircleId(payload);
    final (String, String)? text = reminderText(payload);
    final (String, String)? target = snoozeTarget(payload);
    if (circleId == null || text == null || target == null) return false;
    await _snooze(
      key: target.$1,
      snooze: TaskSnooze(
        circleId: circleId,
        task: SnoozedTask.of(payload),
        subject: target.$2,
        at: _now().toUtc().add(notificationSnooze),
      ),
      title: text.$1,
      body: text.$2,
    );
    return true;
  }

  /// The synced circle of [circleId], for the words of its reminders.
  ReminderCircle _circleOf(String circleId) =>
      _circles
          .where((ReminderCircle item) => item.id == circleId)
          .firstOrNull ??
      ReminderCircle(
        id: circleId,
        name: '',
        viewerId: null,
        viewerIsPatient: false,
        timeZone: defaultPatientZone,
      );

  /// Puts the task of [key] off to [snooze]'s moment, in the task's own
  /// slot: put off again, it keeps one reminder, at the new time. Its
  /// reminder at its planned time, still to come when put off early, is
  /// taken off, and is not set again while the snooze waits. Recording the
  /// task takes the snooze off ([_settleSnoozes]).
  Future<void> _snooze({
    required String key,
    required TaskSnooze snooze,
    required String title,
    required String body,
  }) async {
    await _readSnoozes();
    final DateTime now = _now().toUtc();
    _snoozed.removeWhere(
      (String _, _Snoozed entry) => !entry.snooze.at.isAfter(now),
    );
    final _Snoozed? earlier = _snoozed.remove(key);
    final int slot = earlier?.slot ?? _freeSlot();
    _snoozed[key] = (snooze: snooze, slot: slot);
    // A snooze can be the first reminder this phone sets (a day whose tasks
    // have all passed asks nothing), and without the permission iOS drops
    // it in silence. iOS asks the person only the first time.
    await _phone.requestPermission();
    final Map<int, String> pending = await _phone.pending();
    for (final MapEntry<int, String> entry in pending.entries) {
      if (isReminderPayload(entry.value) &&
          snoozeTarget(entry.value)?.$1 == key) {
        await _phone.cancel(entry.key);
      }
    }
    await _phone.schedule(
      ScheduledNotification(
        id: cardSnoozeIdBase + slot,
        at: snooze.at,
        title: title,
        body: body,
        // It can be put off again, the same as the reminder it came from.
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
    await _saveSnoozes();
  }

  /// A slot no task put off uses; with all of them used, the one put off
  /// first gives up its slot (its reminder is replaced).
  int _freeSlot() {
    final Set<int> used = <int>{
      for (final _Snoozed entry in _snoozed.values) entry.slot,
    };
    for (int slot = 0; slot < maxCardSnoozes; slot++) {
      if (!used.contains(slot)) return slot;
    }
    final String first = _snoozed.keys.first;
    return _snoozed.remove(first)!.slot;
  }

  /// Takes off the snoozes of the doses and measurements recorded since,
  /// and forgets those that came.
  Future<void> _settleSnoozes(
    List<(ReminderCircle, DoseOccurrence)> doses,
    List<(ReminderCircle, MeasurementOccurrence)> measurements,
  ) async {
    await _readSnoozes();
    if (_snoozed.isEmpty) return;
    final DateTime now = _now().toUtc();
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
    for (final String key in _snoozed.keys.toList()) {
      final _Snoozed entry = _snoozed[key]!;
      if (recorded.contains(key)) {
        await _phone.cancel(cardSnoozeIdBase + entry.slot);
      } else if (entry.snooze.at.isAfter(now)) {
        continue;
      }
      _snoozed.remove(key);
      changed = true;
    }
    if (changed) await _saveSnoozes();
  }

  /// Reads the tasks put off once, when first needed.
  Future<void> _readSnoozes() => _snoozesRead ??= _loadSnoozes();

  Future<void> _loadSnoozes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_snoozesKey);
    if (raw == null) return;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      for (final MapEntry<String, dynamic> entry in decoded.entries) {
        final Object? value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final Object? at = value['at'];
        final Object? slot = value['slot'];
        final Object? circleId = value['circle'];
        final Object? subject = value['subject'];
        final DateTime? moment = at is String ? DateTime.tryParse(at) : null;
        final SnoozedTask? task = SnoozedTask.values
            .where((SnoozedTask item) => item.name == value['task'])
            .firstOrNull;
        if (moment == null ||
            slot is! int ||
            circleId is! String ||
            subject is! String ||
            task == null) {
          continue;
        }
        if (slot < 0 || slot >= maxCardSnoozes) continue;
        _snoozed.putIfAbsent(
          entry.key,
          () => (
            snooze: TaskSnooze(
              circleId: circleId,
              task: task,
              subject: subject,
              at: moment.toUtc(),
            ),
            slot: slot,
          ),
        );
      }
    } on FormatException {
      return;
    }
    _publishSnoozes();
  }

  Future<void> _saveSnoozes() async {
    _publishSnoozes();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_snoozed.isEmpty) {
      await prefs.remove(_snoozesKey);
      return;
    }
    await prefs.setString(
      _snoozesKey,
      jsonEncode(<String, Object>{
        for (final MapEntry<String, _Snoozed> entry in _snoozed.entries)
          entry.key: <String, Object>{
            'at': entry.value.snooze.at.toUtc().toIso8601String(),
            'slot': entry.value.slot,
            'circle': entry.value.snooze.circleId,
            'task': entry.value.snooze.task.name,
            'subject': entry.value.snooze.subject,
          },
      }),
    );
  }

  /// Tells the cards and the calendar which tasks are put off, each until
  /// it came.
  void _publishSnoozes() {
    final DateTime now = _now().toUtc();
    _published.value = Map<String, TaskSnooze>.unmodifiable(
      <String, TaskSnooze>{
        for (final MapEntry<String, _Snoozed> entry in _snoozed.entries)
          if (entry.value.snooze.at.isAfter(now)) entry.key: entry.value.snooze,
      },
    );
    _snoozeEnds?.cancel();
    _snoozeEnds = null;
    if (_published.value.isEmpty) return;
    final DateTime next = _published.value.values
        .map((TaskSnooze snooze) => snooze.at)
        .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
    _snoozeEnds = Timer(
      next.difference(now) + const Duration(seconds: 1),
      _publishSnoozes,
    );
  }

  /// Removes every reminder: the person signed out, or the sign-in ended.
  Future<void> clear() async {
    _session++;
    _circles = const <ReminderCircle>[];
    _runner.dropPending();
    await _phone.cancelAll();
    await _readSnoozes();
    _snoozed.clear();
    await _saveSnoozes();
  }

  Future<void> _run() async {
    final int session = _session;
    final List<ReminderCircle> circles = _circles;
    if (circles.isEmpty) {
      await _replace(const <ScheduledNotification>[], session);
      return;
    }
    final DateTime now = _now();
    // Each circle reads [days] of its own patient's days; the reminders
    // end together at the first patient midnight after them.
    DateTime? until;
    final List<(ReminderCircle, DoseOccurrence)> doses =
        <(ReminderCircle, DoseOccurrence)>[];
    final List<(ReminderCircle, MeasurementOccurrence)> measurements =
        <(ReminderCircle, MeasurementOccurrence)>[];
    final List<(ReminderCircle, CareAppointment)> appointments =
        <(ReminderCircle, CareAppointment)>[];
    for (final ReminderCircle circle in circles) {
      // Days as UTC dates, so the phone's own DST never moves one.
      final DateTime today = circle.clock.today(now);
      final DateTime from = DateTime.utc(today.year, today.month, today.day);
      final DateTime to = from.add(const Duration(days: days - 1));
      final DateTime end = circle.clock.momentOf(
        from.add(const Duration(days: days)),
        '00:00',
      );
      if (until == null || end.isBefore(until)) until = end;
      final result = await _medications.getOccurrences(circle.id, from, to);
      if (session != _session) return;
      final List<DoseOccurrence>? list = result.tryGetSuccess();
      // Offline or refused: the reminders already set stay until the next
      // reading.
      if (list == null) return;
      for (final DoseOccurrence dose in list) {
        doses.add((circle, dose));
      }
      try {
        final MeasurementRepository? measurementRepository = _measurements;
        if (measurementRepository != null) {
          final List<MeasurementOccurrence> tasks = await measurementRepository
              .occurrences(circle.id, from, to);
          if (session != _session) return;
          for (final MeasurementOccurrence task in tasks) {
            measurements.add((circle, task));
          }
        }
        final AppointmentRepository? appointmentRepository = _appointments;
        if (appointmentRepository != null) {
          final List<CareAppointment> visits = await appointmentRepository
              .appointments(circle.id);
          if (session != _session) return;
          for (final CareAppointment visit in visits) {
            // Only the patient and the members going with them.
            if (circle.remindsOfAppointment(visit.companionIds)) {
              appointments.add((circle, visit));
            }
          }
        }
      } on Exception {
        // The same as a failed dose reading: keep what is set.
        return;
      }
    }
    await _settleSnoozes(doses, measurements);
    if (session != _session) return;
    final List<ScheduledNotification> planned = planDoseReminders(
      doses: doses,
      measurements: measurements,
      appointments: appointments,
      // The time after the readings, which can take a while on a slow
      // network: a dose that came close meanwhile is not set too late.
      now: _now(),
      texts: texts,
      until: until,
      // The tasks put off have their own slots, and their reminders wait
      // for the new time.
      limit: maxDoseReminders - _snoozed.length,
      snoozed: _snoozed.keys.toSet(),
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
