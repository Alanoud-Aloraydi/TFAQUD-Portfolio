import 'dart:async';
import 'dart:convert';

import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:app/core/services/reminder_circle.dart';

/// Which of an appointment's reminders: the day before, shortly before it,
/// or right after it was saved for today or tomorrow, when the day-before
/// moment had already passed.
enum AppointmentLead { dayBefore, soon, today }

/// The words of the reminders. They are given from outside, so this file
/// needs no translations and the tests can use plain words.
class DoseReminderTexts {
  const DoseReminderTexts({
    required this.title,
    required this.body,
    required this.measurementTitle,
    required this.measurementBody,
    required this.appointmentTitle,
    required this.appointmentBody,
    required this.keepTitle,
    required this.keepBody,
  });

  /// «حان موعد الدواء».
  final String Function(ReminderCircle circle, DoseOccurrence dose) title;

  /// «يا ياسر، لا ننسى ميتفورمين» over the dose, «1 حبة · الساعة 9:00 م».
  final String Function(ReminderCircle circle, DoseOccurrence dose) body;

  /// «ياسر، وقت القياس الحين».
  final String Function(ReminderCircle circle) measurementTitle;

  /// What to measure, «سكر الدم».
  final String Function(
    ReminderCircle circle,
    MeasurementOccurrence measurement,
  )
  measurementBody;

  /// «ياسر! عندك موعد القلب بكرة», or «… بعد ساعتين».
  final String Function(
    ReminderCircle circle,
    AppointmentLead lead,
    CareAppointment appointment,
  )
  appointmentTitle;

  /// «الساعة 4:30 م · مستشفى الملك فهد».
  final String Function(CareAppointment appointment) appointmentBody;

  /// The last note: open the app so the reminders go on.
  final String Function() keepTitle;
  final String Function() keepBody;
}

/// What a dose reminder's payload starts with; the circle's id follows.
const String doseReminderPayload = 'dose:';

/// What a measurement reminder's payload starts with; the circle's id
/// follows.
const String measurementReminderPayload = 'measurement:';

/// What an appointment reminder's payload starts with; the circle's id
/// follows.
const String appointmentReminderPayload = 'appointment:';

/// The payload of the note after the last reminder.
const String keepRemindersPayload = 'reminders:keep';

/// Between a payload's circle and the words a snoozable reminder carries,
/// so «ذكّرني لاحقًا» in the notification can show them again.
const String _textSeparator = '\u001F';

/// [payload] with [title] and [body] after it.
String payloadWithText(String payload, String title, String body) =>
    '$payload$_textSeparator$title$_textSeparator$body';

/// The title and body a reminder's payload carries, or null.
(String, String)? reminderText(String payload) {
  final List<String> parts = payload.split(_textSeparator);
  return parts.length == 3 ? (parts[1], parts[2]) : null;
}

/// iOS keeps at most 64 scheduled notifications for an app (the 64 set
/// last). The reminders of doses, measurements and appointments share
/// [maxDoseReminders] of them, the nearest first; the note after them takes
/// one more, and a snooze one more. A dose put off from its card takes the
/// place of one of the reminders ([maxCardSnoozes]).
const int maxDoseReminders = 60;

/// The ids of the reminders: [reminderIdBase] to [reminderIdBase] + 60.
const int reminderIdBase = 7000;

/// How long before an appointment its second reminder comes; the first
/// comes a day before.
const Duration appointmentSoonLead = Duration(hours: 2);

/// A reminder this close is not set: by the time the phone has it, its
/// moment may have passed. Short, so a medicine saved a minute before its
/// dose is still reminded.
const Duration reminderMargin = Duration(seconds: 10);

/// How long after an appointment is saved its «اليوم» reminder comes, when
/// it was saved after its day-before moment: right away, with time for the
/// phone to set it.
const Duration appointmentSavedLead = Duration(seconds: 30);

/// When an appointment saved after its day-before moment is said right
/// away ([AppointmentLead.today]): [appointmentSavedLead] after it was
/// saved, once (a later refresh finds that moment gone). Null when it was
/// saved earlier, or when its two-hour reminder comes within ten minutes
/// anyway.
DateTime? appointmentAnnouncedAt(CareAppointment visit) {
  final DateTime moment = riyadhMoment(visit.scheduledOn, visit.time);
  final DateTime saved = visit.updatedAt.toUtc();
  if (!saved.isAfter(moment.subtract(const Duration(days: 1)))) return null;
  final DateTime at = saved.add(appointmentSavedLead);
  final DateTime soon = moment.subtract(appointmentSoonLead);
  final bool soonComes =
      soon.isAfter(at) && soon.difference(at) < const Duration(minutes: 10);
  return at.isBefore(moment) && !soonComes ? at : null;
}

/// Whether a scheduled notification is one of the reminders.
bool isReminderPayload(String payload) =>
    payload.startsWith(doseReminderPayload) ||
    payload.startsWith(measurementReminderPayload) ||
    payload.startsWith(appointmentReminderPayload) ||
    payload == keepRemindersPayload;

/// What a simplified-mode "لاحقا" snooze's payload starts with; the
/// circle's id follows, the same as [doseReminderPayload]. A separate
/// prefix and id so [DoseReminders]'s own replace cycle never cancels it
/// as an orphaned reminder.
const String doseSnoozePayload = 'dose-snooze:';

/// The same for a measurement's "ذكّرني لاحقًا".
const String measurementSnoozePayload = 'measurement-snooze:';

/// What a snooze reminds of again.
enum SnoozedTask {
  dose(doseSnoozePayload),
  measurement(measurementSnoozePayload);

  const SnoozedTask(this.payloadPrefix);

  final String payloadPrefix;

  /// What a reminder or snooze [payload] is about: a measurement's stays a
  /// measurement when put off again, anything else is a dose.
  static SnoozedTask of(String payload) =>
      payload.startsWith(measurementReminderPayload) ||
          payload.startsWith(measurementSnoozePayload)
      ? SnoozedTask.measurement
      : SnoozedTask.dose;
}

/// The one slot a snooze uses; a new snooze replaces any pending one.
const int doseSnoozeId = reminderIdBase + maxDoseReminders + 10;

/// The slots of the doses put off from their cards («ذكّرني لاحقًا» on
/// «اليوم»), after the note's: each dose has its own, so two doses put off
/// both come again.
const int cardSnoozeIdBase = reminderIdBase + maxDoseReminders + 1;

/// At most this many doses put off from their cards at once. The reminders
/// to come give up as many places, so the phone's 64 are never passed.
const int maxCardSnoozes = 5;

/// A dose put off from its card: its circle, its time of the plan, and its
/// day.
String doseSnoozeKey(String circleId, DoseOccurrence dose) {
  final DateTime day = dose.scheduledOn;
  return '$circleId|${dose.scheduleId}|${day.year}-${day.month}-${day.day}';
}

/// A dose put off from its card: when it comes again, in which slot.
class _CardSnooze {
  const _CardSnooze(this.at, this.slot);

  final DateTime at;
  final int slot;
}

/// The circle a tapped reminder is about, or null for the note and for
/// notifications that are not reminders.
String? reminderCircleId(String payload) {
  // A snooze action's tap, and the words after the circle, are not part of
  // the circle's id.
  final String plain =
      (isSnoozeTap(payload)
              ? payload.substring(snoozeTapPrefix.length)
              : payload)
          .split(_textSeparator)
          .first;
  for (final String prefix in <String>[
    doseReminderPayload,
    measurementReminderPayload,
    appointmentReminderPayload,
    doseSnoozePayload,
    measurementSnoozePayload,
  ]) {
    if (plain.startsWith(prefix) && plain.length > prefix.length) {
      return plain.substring(prefix.length);
    }
  }
  return null;
}

/// The moment of [time] on [day] in Riyadh. The server keeps days and times
/// in Riyadh (UTC+3, no daylight saving), so this is the same moment on any
/// phone.
DateTime riyadhMoment(DateTime day, String time) {
  final List<String> parts = time.split(':');
  return DateTime.utc(
    day.year,
    day.month,
    day.day,
    int.parse(parts[0]) - 3,
    int.parse(parts[1]),
  );
}

/// The moment a dose is due.
DateTime doseMoment(DoseOccurrence dose) =>
    riyadhMoment(dose.scheduledOn, dose.time);

/// The reminders after [now], the nearest first, at most [limit]:
///
/// * one at each dose not recorded yet (taken or skipped);
/// * one at each measurement not recorded yet;
/// * two for each appointment still to come: a day before it, and
///   [appointmentSoonLead] before it.
///
/// None at or after [until], so the reminders end together and the note
/// after the last one is not far behind the others. After the last one
/// comes a note to open the app, which fires only when the app was not
/// opened in all that time (each opening sets the reminders again, further
/// on).
List<ScheduledNotification> planDoseReminders({
  List<(ReminderCircle, DoseOccurrence)> doses =
      const <(ReminderCircle, DoseOccurrence)>[],
  List<(ReminderCircle, MeasurementOccurrence)> measurements =
      const <(ReminderCircle, MeasurementOccurrence)>[],
  List<(ReminderCircle, CareAppointment)> appointments =
      const <(ReminderCircle, CareAppointment)>[],
  required DateTime now,
  required DoseReminderTexts texts,
  DateTime? until,
  int limit = maxDoseReminders,
}) {
  // A moment in the next few seconds is too close to set: by the time the
  // phone has it, it may have passed.
  final DateTime earliest = now.toUtc().add(reminderMargin);
  bool inWindow(DateTime at) =>
      at.isAfter(earliest) && (until == null || at.isBefore(until));
  final List<_Reminder> upcoming = <_Reminder>[
    for (final (ReminderCircle circle, DoseOccurrence dose) in doses)
      if (dose.record == null && inWindow(doseMoment(dose)))
        _Reminder(
          at: doseMoment(dose),
          circle: circle,
          title: texts.title(circle, dose),
          body: texts.body(circle, dose),
          prefix: doseReminderPayload,
          snoozable: true,
        ),
    for (final (ReminderCircle circle, MeasurementOccurrence task)
        in measurements)
      if (task.record == null &&
          (task.status == MeasurementStatus.upcoming ||
              task.status == MeasurementStatus.due) &&
          inWindow(riyadhMoment(task.scheduledOn, task.time)))
        _Reminder(
          at: riyadhMoment(task.scheduledOn, task.time),
          circle: circle,
          title: texts.measurementTitle(circle),
          body: texts.measurementBody(circle, task),
          prefix: measurementReminderPayload,
          snoozable: true,
        ),
    for (final (ReminderCircle circle, CareAppointment visit) in appointments)
      if (visit.status == AppointmentStatus.scheduled)
        for (final (AppointmentLead lead, Duration before)
            in const <(AppointmentLead, Duration)>[
              (AppointmentLead.dayBefore, Duration(days: 1)),
              (AppointmentLead.soon, appointmentSoonLead),
            ])
          if (inWindow(
            riyadhMoment(visit.scheduledOn, visit.time).subtract(before),
          ))
            _Reminder(
              at: riyadhMoment(visit.scheduledOn, visit.time).subtract(before),
              circle: circle,
              title: texts.appointmentTitle(circle, lead, visit),
              body: texts.appointmentBody(visit),
              prefix: appointmentReminderPayload,
            ),
    // Saved for today or tomorrow after its day-before moment: said once,
    // right away, so a change made today is not silent until two hours
    // before.
    for (final (ReminderCircle circle, CareAppointment visit) in appointments)
      if (visit.status == AppointmentStatus.scheduled)
        if (appointmentAnnouncedAt(visit) case final DateTime at
            when inWindow(at))
          _Reminder(
            at: at,
            circle: circle,
            title: texts.appointmentTitle(circle, AppointmentLead.today, visit),
            body: texts.appointmentBody(visit),
            prefix: appointmentReminderPayload,
          ),
  ]..sort((_Reminder a, _Reminder b) => a.at.compareTo(b.at));
  final List<_Reminder> kept = upcoming.take(limit).toList();
  return <ScheduledNotification>[
    for (int i = 0; i < kept.length; i++)
      ScheduledNotification(
        id: reminderIdBase + i,
        at: kept[i].at,
        title: kept[i].title,
        body: kept[i].body,
        // A dose or measurement carries its words, for «ذكّرني لاحقًا».
        payload: kept[i].snoozable
            ? payloadWithText(
                '${kept[i].prefix}${kept[i].circle.id}',
                kept[i].title,
                kept[i].body,
              )
            : '${kept[i].prefix}${kept[i].circle.id}',
        thread: kept[i].circle.id,
        snoozable: kept[i].snoozable,
      ),
    if (kept.isNotEmpty)
      ScheduledNotification(
        id: reminderIdBase + maxDoseReminders,
        at: kept.last.at.add(const Duration(minutes: 1)),
        title: texts.keepTitle(),
        body: texts.keepBody(),
        payload: keepRemindersPayload,
      ),
  ];
}

/// One reminder before it gets its id.
class _Reminder {
  const _Reminder({
    required this.at,
    required this.circle,
    required this.title,
    required this.body,
    required this.prefix,
    this.snoozable = false,
  });

  final DateTime at;
  final ReminderCircle circle;
  final String title;
  final String body;
  final String prefix;
  final bool snoozable;
}

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
  Future<void>? _running;
  bool _again = false;
  bool _asked = false;

  /// Goes up at each [clear], so a reading that ends after a sign-out sets
  /// nothing.
  int _session = 0;

  static const String _snoozesKey = 'dose_card_snoozes';

  /// The doses put off from their cards, by [doseSnoozeKey], the first put
  /// off first. Kept on the phone, so a card still shows its time after the
  /// app is opened again.
  final Map<String, _CardSnooze> _cardSnoozes = <String, _CardSnooze>{};
  Future<void>? _snoozesRead;
  final ValueNotifier<Map<String, DateTime>> _snoozed =
      ValueNotifier<Map<String, DateTime>>(const <String, DateTime>{});
  Timer? _snoozeEnds;

  /// When each dose put off from its card comes again, by [doseSnoozeKey]:
  /// the card shows «بنذكّرك 2:36 م» until then.
  ValueListenable<Map<String, DateTime>> get snoozedDoses {
    unawaited(_readSnoozes());
    return _snoozed;
  }

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

  /// Reminds of one dose or measurement again [after] from now: «ذكّرني
  /// لاحقًا» in either mode. Local-only: no plan or record
  /// changes, so nothing to undo if the app is never reopened before it
  /// fires.
  Future<void> snooze({
    required String circleId,
    required SnoozedTask task,
    required String title,
    required String body,
    required Duration after,
  }) async {
    // A snooze can be the first reminder this phone sets (a day whose tasks
    // have all passed asks nothing), and without the permission iOS drops
    // it in silence. iOS asks the person only the first time.
    await _phone.requestPermission();
    await _phone.schedule(
      ScheduledNotification(
        id: doseSnoozeId,
        at: _now().toUtc().add(after),
        title: title,
        body: body,
        // It can be put off again, the same as the reminder it came from.
        payload: payloadWithText('${task.payloadPrefix}$circleId', title, body),
        snoozable: true,
      ),
    );
  }

  /// «ذكّرني لاحقًا» from a notification: [tap] is the snooze action of a
  /// reminder, which carries its words; it comes again in
  /// [notificationSnooze], still a dose or a measurement as it was. False
  /// when the tap is not a snoozable reminder.
  Future<bool> snoozeTap(String tap) async {
    if (!isSnoozeTap(tap)) return false;
    final String payload = tap.substring(snoozeTapPrefix.length);
    final String? circleId = reminderCircleId(payload);
    final (String, String)? text = reminderText(payload);
    if (circleId == null || text == null) return false;
    await snooze(
      circleId: circleId,
      task: SnoozedTask.of(payload),
      title: text.$1,
      body: text.$2,
      after: notificationSnooze,
    );
    return true;
  }

  /// Cancels a pending snooze: the task it was for got recorded another way.
  Future<void> cancelSnooze() => _phone.cancel(doseSnoozeId);

  /// «ذكّرني لاحقًا» on a dose's card: its reminder again [after] from now,
  /// in the dose's own slot, and its card shows the new time
  /// ([snoozedDoses]). Recording the dose takes it off. Put off again, the
  /// dose keeps one reminder, at the new time.
  Future<void> snoozeDose({
    required String circleId,
    required DoseOccurrence dose,
    required String title,
    required String body,
    required Duration after,
  }) async {
    await _readSnoozes();
    final DateTime now = _now().toUtc();
    _cardSnoozes.removeWhere(
      (String key, _CardSnooze snooze) => !snooze.at.isAfter(now),
    );
    final String key = doseSnoozeKey(circleId, dose);
    final _CardSnooze? earlier = _cardSnoozes.remove(key);
    final int slot = earlier?.slot ?? _freeSlot();
    final DateTime at = now.add(after);
    _cardSnoozes[key] = _CardSnooze(at, slot);
    // As [snooze]: without the permission iOS drops it in silence.
    await _phone.requestPermission();
    await _phone.schedule(
      ScheduledNotification(
        id: cardSnoozeIdBase + slot,
        at: at,
        title: title,
        body: body,
        payload: payloadWithText('$doseSnoozePayload$circleId', title, body),
        thread: circleId,
        snoozable: true,
      ),
    );
    await _saveSnoozes();
  }

  /// A slot no dose put off uses; with all of them used, the one put off
  /// first gives up its slot (its reminder is replaced).
  int _freeSlot() {
    final Set<int> used = <int>{
      for (final _CardSnooze snooze in _cardSnoozes.values) snooze.slot,
    };
    for (int slot = 0; slot < maxCardSnoozes; slot++) {
      if (!used.contains(slot)) return slot;
    }
    final String first = _cardSnoozes.keys.first;
    return _cardSnoozes.remove(first)!.slot;
  }

  /// Takes off the snoozes of doses recorded since, and forgets those that
  /// came.
  Future<void> _settleSnoozes(
    List<(ReminderCircle, DoseOccurrence)> doses,
  ) async {
    await _readSnoozes();
    if (_cardSnoozes.isEmpty) return;
    final DateTime now = _now().toUtc();
    final Set<String> recorded = <String>{
      for (final (ReminderCircle circle, DoseOccurrence dose) in doses)
        if (dose.record != null) doseSnoozeKey(circle.id, dose),
    };
    bool changed = false;
    for (final String key in _cardSnoozes.keys.toList()) {
      final _CardSnooze snooze = _cardSnoozes[key]!;
      if (recorded.contains(key)) {
        await _phone.cancel(cardSnoozeIdBase + snooze.slot);
      } else if (snooze.at.isAfter(now)) {
        continue;
      }
      _cardSnoozes.remove(key);
      changed = true;
    }
    if (changed) await _saveSnoozes();
  }

  /// Reads the doses put off from their cards once, when first needed.
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
        final DateTime? moment = at is String ? DateTime.tryParse(at) : null;
        if (moment == null || slot is! int) continue;
        if (slot < 0 || slot >= maxCardSnoozes) continue;
        _cardSnoozes.putIfAbsent(entry.key, () => _CardSnooze(moment, slot));
      }
    } on FormatException {
      return;
    }
    _publishSnoozes();
  }

  Future<void> _saveSnoozes() async {
    _publishSnoozes();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_cardSnoozes.isEmpty) {
      await prefs.remove(_snoozesKey);
      return;
    }
    await prefs.setString(
      _snoozesKey,
      jsonEncode(<String, Object>{
        for (final MapEntry<String, _CardSnooze> entry in _cardSnoozes.entries)
          entry.key: <String, Object>{
            'at': entry.value.at.toUtc().toIso8601String(),
            'slot': entry.value.slot,
          },
      }),
    );
  }

  /// Tells the cards when their doses come again, each until it came.
  void _publishSnoozes() {
    final DateTime now = _now().toUtc();
    _snoozed.value = Map<String, DateTime>.unmodifiable(<String, DateTime>{
      for (final MapEntry<String, _CardSnooze> entry in _cardSnoozes.entries)
        if (entry.value.at.isAfter(now)) entry.key: entry.value.at,
    });
    _snoozeEnds?.cancel();
    _snoozeEnds = null;
    if (_snoozed.value.isEmpty) return;
    final DateTime next = _snoozed.value.values.reduce(
      (DateTime a, DateTime b) => a.isBefore(b) ? a : b,
    );
    _snoozeEnds = Timer(
      next.difference(now) + const Duration(seconds: 1),
      _publishSnoozes,
    );
  }

  /// Removes every reminder: the person signed out, or the sign-in ended.
  Future<void> clear() async {
    _session++;
    _circles = const <ReminderCircle>[];
    _again = false;
    await _phone.cancelAll();
    await _readSnoozes();
    _cardSnoozes.clear();
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
    final DateTime riyadh = riyadhNow(now);
    final DateTime from = DateTime.utc(riyadh.year, riyadh.month, riyadh.day);
    final DateTime to = from.add(const Duration(days: days - 1));
    // Midnight in Riyadh after the last day read.
    final DateTime until = from
        .add(const Duration(days: days))
        .subtract(const Duration(hours: 3));
    final List<(ReminderCircle, DoseOccurrence)> doses =
        <(ReminderCircle, DoseOccurrence)>[];
    final List<(ReminderCircle, MeasurementOccurrence)> measurements =
        <(ReminderCircle, MeasurementOccurrence)>[];
    final List<(ReminderCircle, CareAppointment)> appointments =
        <(ReminderCircle, CareAppointment)>[];
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
    await _settleSnoozes(doses);
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
      // The doses put off from their cards have their own slots.
      limit: maxDoseReminders - _cardSnoozes.length,
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
