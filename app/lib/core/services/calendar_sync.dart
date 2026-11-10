import 'dart:async';
import 'dart:convert';

import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/dose_reminders.dart'
    show TaskSnooze;
import 'package:app/core/services/reminders/reminder_payloads.dart'
    show SnoozedTask;
import 'package:app/core/utils/coalescing_runner.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:shared_preferences/shared_preferences.dart';

/// One kind of event this feature can mirror, switched on per circle.
enum CalendarSyncCategory { doses, measurements, appointments }

/// The words of the calendar's events, in the voice of the reminders: «لا
/// ننسى الأنسولين لـنورة», «وقت القياس: سكر الدم», «لا ننسى موعدك: عيادة
/// السكري». Without the «يا ياسر،» of a notification, so the medicine's or
/// clinic's name is what a small calendar box shows first.
class CalendarEventTexts {
  const CalendarEventTexts({
    required this.dose,
    required this.doseNote,
    required this.measurement,
    required this.appointment,
    required this.appointmentNote,
  });

  /// A dose of [medicine] in [circleId].
  final String Function(String circleId, String medicine) dose;

  /// The line inside a dose's event: «حان موعد الدواء».
  final String Function() doseNote;

  /// A reading of [kind] in [circleId].
  final String Function(String circleId, MeasurementKind kind) measurement;

  /// [visit] in [circleId].
  final String Function(String circleId, CareAppointment visit) appointment;

  /// The line inside an appointment's event, the same as its notification:
  /// «عيادة السكري · الساعة 4:30 م · مستشفى الملك فهد».
  final String Function(CareAppointment visit) appointmentNote;
}

/// The Arabic words, read when the events are set (the translations are
/// loaded by then).
final CalendarEventTexts calendarEventTexts = CalendarEventTexts(
  dose: (String circleId, String medicine) {
    final String? patient = CareVoice.patientOf(circleId);
    return patient == null
        ? 'reminders.dose_call'.tr(args: <String>[withArticle(medicine)])
        : 'reminders.dose_call_for'.tr(
            args: <String>[withArticle(medicine), patient],
          );
  },
  doseNote: () => 'reminders.dose_title'.tr(),
  measurement: (String circleId, MeasurementKind kind) {
    final String name = switch (kind) {
      MeasurementKind.glucose => 'measurements.glucose'.tr(),
      MeasurementKind.bp => 'measurements.bp'.tr(),
    };
    final String? patient = CareVoice.patientOf(circleId);
    return 'reminders.calendar_measurement'.tr(
      args: <String>[
        if (patient == null)
          name
        else
          'reminders.measurement_body_for'.tr(args: <String>[name, patient]),
      ],
    );
  },
  appointment: (String circleId, CareAppointment visit) {
    final String? patient = CareVoice.patientOf(circleId);
    final String clinic = clinicName(visit.specialty);
    return patient == null
        ? 'reminders.calendar_appointment'.tr(args: <String>[clinic])
        : 'reminders.calendar_appointment_for'.tr(
            args: <String>[patient, clinic],
          );
  },
  appointmentNote: (CareAppointment visit) {
    final String place = visit.place?.trim() ?? '';
    final List<String> args = <String>[
      clinicName(visit.specialty),
      clockText(visit.time),
      if (place.isNotEmpty) place,
    ];
    return (place.isEmpty
            ? 'reminders.appointment_body'
            : 'reminders.appointment_body_place')
        .tr(args: args);
  },
);

/// One event this feature wants on the phone's calendar, before it exists.
class _DesiredEvent {
  const _DesiredEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.reminders,
    required this.zone,
    this.note,
    this.place,
    this.recurrence,
    this.until,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final List<Duration> reminders;

  /// The patient's IANA zone: the calendar keeps the event, and repeats
  /// it, at the patient's wall clock there, across DST, wherever this
  /// phone is.
  final String zone;
  final String? note;
  final String? place;
  final RecurrenceRule? recurrence;

  /// The moment a repeating event repeats up to ([recurrence] ends there).
  final DateTime? until;
}

/// What this phone remembers of an event it made: the calendar's id for
/// it, and its title and first start, to find it again when the calendar
/// gave it another id (a calendar of another account can, once it syncs);
/// the calendar it is in (null: the phone's default one); and, for a
/// repeating one, the day it repeats to. An older event has less.
class _SavedEvent {
  const _SavedEvent(
    this.id, {
    this.title,
    this.start,
    this.until,
    this.calendar,
  });

  final String id;
  final String? title;
  final DateTime? start;
  final DateTime? until;
  final String? calendar;

  static _SavedEvent? fromJson(Object? value) {
    if (value is String) return _SavedEvent(value);
    if (value is! Map<String, dynamic>) return null;
    final Object? id = value['id'];
    final Object? title = value['title'];
    final Object? start = value['start'];
    final Object? until = value['until'];
    final Object? calendar = value['calendar'];
    if (id is! String) return null;
    return _SavedEvent(
      id,
      title: title is String ? title : null,
      start: start is String ? DateTime.tryParse(start) : null,
      until: until is String ? DateTime.tryParse(until) : null,
      calendar: calendar is String ? calendar : null,
    );
  }

  Map<String, String> toJson() => <String, String>{
    'id': id,
    'title': ?title,
    'start': ?start?.toIso8601String(),
    'until': ?until?.toIso8601String(),
    'calendar': ?calendar,
  };
}

/// Mirrors active medication and measurement schedules, and upcoming
/// appointments, onto the phone's own Calendar app — a backup to the push
/// and local-notification reminders, for a dose that must not be missed.
///
/// Opt-in ([setEnabled]), off by default, and chosen per circle and per
/// category: someone in several circles may want only one circle's
/// appointments on their calendar, say. A dose or appointment written into
/// the phone's shared calendar is visible to anything else with calendar
/// access, unlike the rest of this app's circle-scoped data. Turning a
/// switch off takes its events off the phone's calendar again.
///
/// The events go in the app's own calendar, «تفقّد» ([calendarName]), so
/// they can all go in one step: signing out deletes the whole calendar,
/// and the person can delete it in the Calendar app too. Deleting the app
/// leaves a calendar behind (iOS tells an app nothing when it is deleted),
/// so a repeating event repeats only two weeks ahead ([_ahead]) and is made
/// again, further ahead, by a refresh when one week is left: while the app
/// is used its events go on, and after it is deleted their alerts stop
/// within two weeks. A «تفقّد» calendar left by an earlier install is
/// deleted before a new one is made. Without full calendar access the
/// events go in the phone's default calendar, as before.
///
/// Nothing here is stored on the server. Each phone keeps its own small map
/// of "key it created" → "calendar event" in [SharedPreferences], and on
/// every [refresh] recomputes the full desired set from the plans and
/// appointments the signed-in person can see, deleting what is no longer
/// wanted and creating what is missing — the same reconcile-from-scratch
/// shape as [ReminderCircle]'s own local notifications, so an edited or
/// discontinued plan is picked up automatically, never left stale. An event
/// the calendar would not delete yet (no full access, say) stays in the map
/// and is deleted at a later refresh.
///
/// A dose or measurement put off with «ذكّرني لاحقًا» ([snoozes]) gets one
/// more event, once, at its new time, in a category that is turned on; it
/// goes when the task is recorded or its time has come.
class CalendarSync {
  CalendarSync(
    this._medications,
    this._measurements,
    this._appointments, {
    ValueListenable<Map<String, TaskSnooze>>? snoozes,
    DeviceCalendar? calendar,
    CalendarEventTexts? texts,
    DateTime Function()? clock,
  }) : _snoozes = snoozes,
       _calendar = calendar ?? DeviceCalendar.instance,
       _texts = texts ?? calendarEventTexts,
       _now = clock ?? DateTime.now {
    // Any accepted plan or appointment change reconciles the calendar right
    // away, not just on the next app resume.
    _medications.changes.listen((_) => unawaited(refresh()));
    _measurements.changes.listen((_) => unawaited(refresh()));
    _appointments.changes.listen((_) => unawaited(refresh()));
    // As does a task put off, or one whose new time came.
    snoozes?.addListener(() => unawaited(refresh()));
  }

  final MedicationsUseCase _medications;
  final MeasurementRepository _measurements;
  final AppointmentRepository _appointments;
  final ValueListenable<Map<String, TaskSnooze>>? _snoozes;
  final DeviceCalendar _calendar;
  final CalendarEventTexts _texts;

  /// The instant source; the system clock unless a test injects one.
  final DateTime Function() _now;

  /// What the rest of a put-off task's key starts with: its event is once,
  /// not repeating.
  static const String _snoozePart = 'snooze';

  static const String _selectionsKey = 'calendar_sync_selections';
  static const String _eventsKey = 'calendar_sync_events';

  /// The id of the app's own calendar, once made.
  static const String _calendarKey = 'calendar_sync_calendar';

  /// The name of the app's own calendar on the phone.
  static const String calendarName = 'تفقّد';

  /// The app's green («leaf»), for the calendar's dot.
  static const String _calendarColor = '#A8D5BA';

  /// How far ahead a repeating event repeats.
  static const Duration _ahead = Duration(days: 14);

  /// With less than this left, a refresh makes the event again, [_ahead]
  /// from then: at most once a week.
  static const Duration _extendWithin = Duration(days: 7);

  /// What the keys of this version start with. A key of an older version
  /// is not wanted any more, so its event is replaced: v2 events were in
  /// the default calendar and repeated with no end.
  static const String _keyVersion = 'v3';

  /// A key of any version: «v2:…», «v3:…».
  static final RegExp _versioned = RegExp(r'^v\d+$');

  List<ReminderCircle> _circles = const <ReminderCircle>[];

  /// Whether [sync] gave the circles yet. Before it, a refresh would find no
  /// circle and delete every event, to make them again a moment later.
  bool _synced = false;
  late final CoalescingRunner _runner = CoalescingRunner(_run);
  int _session = 0;

  /// Whether full calendar access was asked for in this run of the app.
  bool _askedForFull = false;

  String _selectionKey(String circleId, CalendarSyncCategory category) =>
      '$circleId:${category.name}';

  /// A key for one event of [circle]'s [category]: «v2:c-1:doses:…».
  String _eventKey(
    ReminderCircle circle,
    CalendarSyncCategory category,
    String rest,
  ) => '$_keyVersion:${_selectionKey(circle.id, category)}:$rest';

  Future<Set<String>> _selections(SharedPreferences prefs) async =>
      (prefs.getStringList(_selectionsKey) ?? const <String>[]).toSet();

  /// Whether this circle's category is turned on.
  Future<bool> isEnabled(String circleId, CalendarSyncCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    return selections.contains(_selectionKey(circleId, category));
  }

  /// Turns one circle's category on or off; [refresh] reconciles the
  /// calendar to match every selection right after: its events are added,
  /// or taken off the phone's calendar.
  Future<void> setEnabled(
    String circleId,
    CalendarSyncCategory category,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    final String key = _selectionKey(circleId, category);
    final bool changed = value ? selections.add(key) : selections.remove(key);
    if (!changed) return;
    await prefs.setStringList(_selectionsKey, selections.toList());
    if (value) _calendar.autoPermissions = AutoPermissionMode.full;
    await refresh();
  }

  /// The circles to mirror, from now on. Called when the home data loads.
  Future<void> sync(List<ReminderCircle> circles) {
    _circles = List<ReminderCircle>.unmodifiable(circles);
    _synced = true;
    return refresh();
  }

  /// Recomputes the desired events and reconciles the calendar to match.
  /// One reading runs at a time; a call during it makes one more right after.
  Future<void> refresh() => _runner.run();

  /// Removes every event this feature made, with the app's own calendar:
  /// the person signed out. Also clears every selection — they are stored
  /// on the device, not the account, so the next person to sign in on this
  /// device must opt in themselves. An event the calendar would not delete
  /// now is deleted at the next refresh.
  Future<void> clear() async {
    _session++;
    _circles = const <ReminderCircle>[];
    _synced = false;
    _runner.dropPending();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectionsKey);
    await _removeAll(prefs);
  }

  Future<void> _run() async {
    if (!_synced) return;
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    final int session = _session;
    final List<ReminderCircle> circles = _circles;
    final Map<String, _DesiredEvent> desired = <String, _DesiredEvent>{};
    // The circles' categories that could not be read now (offline, say):
    // their events stay as they are, rather than leaving the calendar until
    // the next reading.
    final Set<String> unread = <String>{};
    for (final ReminderCircle circle in circles) {
      for (final CalendarSyncCategory category in CalendarSyncCategory.values) {
        if (session != _session) return;
        final String selection = _selectionKey(circle.id, category);
        if (!selections.contains(selection)) continue;
        final bool read = switch (category) {
          CalendarSyncCategory.doses => await _collectDoses(circle, desired),
          CalendarSyncCategory.measurements => await _collectMeasurements(
            circle,
            desired,
          ),
          CalendarSyncCategory.appointments => await _collectAppointments(
            circle,
            desired,
          ),
        };
        if (!read) unread.add(selection);
      }
    }
    _collectSnoozes(circles, selections, desired);
    if (session != _session) return;
    await _reconcile(prefs, desired, unread, session);
  }

  /// One event at the new time of each dose or measurement put off, in a
  /// circle and category that are turned on, in the words of that task's
  /// own events.
  void _collectSnoozes(
    List<ReminderCircle> circles,
    Set<String> selections,
    Map<String, _DesiredEvent> desired,
  ) {
    final Map<String, TaskSnooze> snoozes =
        _snoozes?.value ?? const <String, TaskSnooze>{};
    for (final MapEntry<String, TaskSnooze> entry in snoozes.entries) {
      final TaskSnooze snooze = entry.value;
      final ReminderCircle? circle = circles
          .where((ReminderCircle item) => item.id == snooze.circleId)
          .firstOrNull;
      final CalendarSyncCategory category = switch (snooze.task) {
        SnoozedTask.dose => CalendarSyncCategory.doses,
        SnoozedTask.measurement => CalendarSyncCategory.measurements,
      };
      if (circle == null ||
          !selections.contains(_selectionKey(circle.id, category))) {
        continue;
      }
      final String? title = switch (snooze.task) {
        SnoozedTask.dose => _texts.dose(circle.id, snooze.subject),
        SnoozedTask.measurement => switch (MeasurementKind.values
            .where((MeasurementKind kind) => kind.name == snooze.subject)
            .firstOrNull) {
          final MeasurementKind kind => _texts.measurement(circle.id, kind),
          null => null,
        },
      };
      if (title == null) continue;
      final DateTime start = snooze.at.toLocal();
      // The moment is part of the key: put off again, the event moves.
      desired[_eventKey(
        circle,
        category,
        '$_snoozePart:${snooze.at.millisecondsSinceEpoch}:${entry.key}',
      )] = _DesiredEvent(
        title: title,
        note: snooze.task == SnoozedTask.dose ? _texts.doseNote() : null,
        zone: circle.timeZone,
        start: start,
        end: start.add(const Duration(minutes: 15)),
        reminders: const <Duration>[Duration.zero],
      );
    }
  }

  Future<bool> _collectDoses(
    ReminderCircle circle,
    Map<String, _DesiredEvent> desired,
  ) async {
    final result = await _medications.getPlans(circle.id);
    final plans = result.tryGetSuccess();
    if (plans == null) return false;
    final PatientClock clock = circle.clock;
    final DateTime ahead = _now().toUtc().add(_ahead);
    for (final plan in plans) {
      if (plan.isPreviousOn(clock.today())) continue;
      final version = plan.version;
      final DateTime from = _from(clock, version.effectiveFromOn, _now());
      for (final MedicationSchedule schedule in version.schedules) {
        // The time is part of the key: a dose moved to another time gets a
        // fresh event.
        final String key = _eventKey(
          circle,
          CalendarSyncCategory.doses,
          '${schedule.id}:${schedule.time}',
        );
        final String title = _texts.dose(circle.id, version.name);
        final DateTime start;
        final RecurrenceRule recurrence;
        switch (schedule.repeat) {
          // A monthly dose as one monthly event on its days of the month (1
          // to 28, which every month has).
          case ScheduleRepeat.monthly:
            final List<int> days = schedule.monthDays.toList()..sort();
            if (days.isEmpty) continue;
            start = _nextMonthDay(clock, from, schedule.time, days);
            recurrence = MonthlyRecurrence(
              daysOfMonth: days,
              end: UntilEnd(_until(start, ahead)),
            );
          // A dose every few days as one event repeating every that many
          // days («FREQ=DAILY;INTERVAL=3»), from its first day on or after
          // [from] on the count from the start of the treatment.
          case ScheduleRepeat.interval:
            final int? every = schedule.intervalDays;
            if (every == null || every < 1) continue;
            start = _nextIntervalDay(
              clock,
              from,
              schedule.time,
              version.startsOn,
              every,
            );
            recurrence = DailyRecurrence(
              interval: every,
              end: UntilEnd(_until(start, ahead)),
            );
          case ScheduleRepeat.weekly:
            start = _nextOccurrence(
              clock,
              from,
              schedule.time,
              schedule.weekdays,
            );
            recurrence = WeeklyRecurrence(
              daysOfWeek: schedule.weekdays.map(_dayOfWeek).toList(),
              end: UntilEnd(_until(start, ahead)),
            );
        }
        desired[key] = _DesiredEvent(
          title: title,
          zone: circle.timeZone,
          note: _texts.doseNote(),
          start: start,
          end: start.add(const Duration(minutes: 15)),
          reminders: const <Duration>[Duration.zero],
          recurrence: recurrence,
          until: _until(start, ahead),
        );
      }
    }
    return true;
  }

  Future<bool> _collectMeasurements(
    ReminderCircle circle,
    Map<String, _DesiredEvent> desired,
  ) async {
    final List<MeasurementPlan> plans;
    try {
      plans = await _measurements.plans(circle.id);
    } on Exception {
      return false;
    }
    final PatientClock clock = circle.clock;
    final DateTime ahead = _now().toUtc().add(_ahead);
    for (final plan in plans) {
      if (plan.stoppedAt != null) continue;
      final version = plan.version;
      final DateTime from = _from(clock, version.effectiveFromOn, _now());
      // One event per reading time.
      final List<MeasurementTime> readings = version.readingTimes;
      for (int index = 0; index < readings.length; index++) {
        final DateTime start = _nextOccurrence(
          clock,
          from,
          readings[index].time,
          version.weekdays,
        );
        desired[_eventKey(
          circle,
          CalendarSyncCategory.measurements,
          '${version.id}:$index:${readings[index].time}',
        )] = _DesiredEvent(
          title: _texts.measurement(circle.id, plan.kind),
          zone: circle.timeZone,
          start: start,
          end: start.add(const Duration(minutes: 15)),
          reminders: const <Duration>[Duration.zero],
          recurrence: WeeklyRecurrence(
            daysOfWeek: version.weekdays.map(_dayOfWeek).toList(),
            end: UntilEnd(_until(start, ahead)),
          ),
          until: _until(start, ahead),
        );
      }
    }
    return true;
  }

  Future<bool> _collectAppointments(
    ReminderCircle circle,
    Map<String, _DesiredEvent> desired,
  ) async {
    final List<CareAppointment> appointments;
    try {
      appointments = await _appointments.appointments(circle.id);
    } on Exception {
      return false;
    }
    final DateTime now = _now();
    for (final appointment in appointments) {
      if (appointment.status != AppointmentStatus.scheduled) continue;
      // The same people as its reminders: the patient and those going.
      if (!circle.remindsOfAppointment(appointment.companionIds)) continue;
      // The real moment of the patient's wall-clock time (not
      // [CareAppointment.scheduledAt], a wall time for ordering), so a
      // phone in any zone shows it at the right time.
      final DateTime at = circle.clock
          .momentOf(appointment.scheduledOn, appointment.time)
          .toLocal();
      if (at.isBefore(now)) continue;
      // The date and time are part of the key: an edited appointment gets a
      // new key, so the stale event is deleted and a fresh one created,
      // rather than silently keeping the old time.
      final String key = _eventKey(
        circle,
        CalendarSyncCategory.appointments,
        '${appointment.id}:'
        '${appointment.scheduledOn.toIso8601String()}:${appointment.time}',
      );
      final String place = appointment.place?.trim() ?? '';
      desired[key] = _DesiredEvent(
        title: _texts.appointment(circle.id, appointment),
        zone: circle.timeZone,
        note: _texts.appointmentNote(appointment),
        place: place.isEmpty ? null : place,
        start: at,
        end: at.add(const Duration(hours: 1)),
        // The same as its notifications: a day before, and two hours before.
        reminders: const <Duration>[Duration(days: 1), Duration(hours: 2)],
      );
    }
    return true;
  }

  Future<void> _reconcile(
    SharedPreferences prefs,
    Map<String, _DesiredEvent> desired,
    Set<String> unread,
    int session,
  ) async {
    final Map<String, _SavedEvent> saved = _readSaved(prefs);
    await _forgetDeletedCalendar(prefs, saved);
    final String? own = prefs.getString(_calendarKey);
    // Not wanted any more; or wanted with other words, near the end of its
    // two weeks, or outside the app's calendar now that it has one: taken
    // off (and the wanted ones made again).
    final List<String> stale = <String>[];
    for (final MapEntry<String, _SavedEvent> entry in saved.entries) {
      final _DesiredEvent? wanted = desired[entry.key];
      final _SavedEvent event = entry.value;
      if (wanted != null
          ? wanted.title != event.title ||
                _endsSoon(event) ||
                (own != null && event.calendar != own)
          : !unread.contains(_groupOf(entry.key))) {
        stale.add(entry.key);
      }
    }
    if (stale.isNotEmpty && await _fullAccess()) {
      final Set<String> known = <String>{
        for (final _SavedEvent event in saved.values) event.id,
      };
      for (final String key in stale) {
        if (session != _session) return;
        if (await _delete(key, saved[key]!, known)) saved.remove(key);
      }
    }
    // The wanted events not on the calendar. One whose old event could not
    // be taken off yet stays as it is, until it can.
    final List<MapEntry<String, _DesiredEvent>> missing = desired.entries
        .where((MapEntry<String, _DesiredEvent> e) => !saved.containsKey(e.key))
        .toList();
    final String? calendarId = missing.isEmpty
        ? null
        : await _ownCalendar(prefs);
    if (session != _session) return;
    for (final MapEntry<String, _DesiredEvent> entry in missing) {
      if (session != _session) return;
      final String? id = await _createEvent(entry.value, calendarId);
      if (id != null) {
        saved[entry.key] = _SavedEvent(
          id,
          title: entry.value.title,
          start: entry.value.start,
          until: entry.value.until,
          calendar: calendarId,
        );
      }
    }
    if (session != _session) return;
    await _writeSaved(prefs, saved);
    // Nothing on the app's calendar any more: it goes too, until needed.
    if (saved.isEmpty &&
        prefs.getString(_calendarKey) != null &&
        await _fullAccess()) {
      await _deleteOwnCalendar(prefs);
    }
  }

  /// Takes off every event this phone made: the app's whole calendar at
  /// once, then, one by one, any put in the phone's default calendar.
  Future<void> _removeAll(SharedPreferences prefs) async {
    final Map<String, _SavedEvent> saved = _readSaved(prefs);
    final String? own = prefs.getString(_calendarKey);
    if ((saved.isNotEmpty || own != null) && await _fullAccess()) {
      if (own != null && await _deleteOwnCalendar(prefs)) {
        saved.removeWhere((String _, _SavedEvent e) => e.calendar == own);
      }
      final Set<String> known = <String>{
        for (final _SavedEvent event in saved.values) event.id,
      };
      for (final String key in saved.keys.toList()) {
        if (await _delete(key, saved[key]!, known)) saved.remove(key);
      }
    }
    await _writeSaved(prefs, saved);
  }

  /// Whether a repeating event is near the end of its two weeks.
  bool _endsSoon(_SavedEvent event) {
    final DateTime? until = event.until;
    return until != null && until.difference(_now()) < _extendWithin;
  }

  /// The id of the app's own calendar, made the first time it is needed;
  /// null when the phone will not make one (no full access, or no calendar
  /// account that takes a new calendar): the events then go in the phone's
  /// default calendar.
  ///
  /// A «تفقّد» calendar this install did not make was left by an earlier
  /// one (deleting the app leaves its calendar): it is deleted, with its
  /// events, before a new one is made.
  Future<String?> _ownCalendar(SharedPreferences prefs) async {
    final String? known = prefs.getString(_calendarKey);
    if (known != null) return known;
    if (!await _fullAccess()) return null;
    try {
      for (final Calendar left in await _calendar.listCalendars()) {
        if (left.name == calendarName && !left.readOnly) {
          await _calendar.deleteCalendar(left.id);
        }
      }
      final String id = await _calendar.createCalendar(
        name: calendarName,
        colorHex: _calendarColor,
      );
      await prefs.setString(_calendarKey, id);
      return id;
    } on Exception {
      return null;
    }
  }

  /// The app's calendar was deleted (in the Calendar app, say), and its
  /// events with it: they are forgotten here, so they are made again.
  Future<void> _forgetDeletedCalendar(
    SharedPreferences prefs,
    Map<String, _SavedEvent> saved,
  ) async {
    final String? own = prefs.getString(_calendarKey);
    if (own == null || !await _fullAccess()) return;
    try {
      final List<Calendar> calendars = await _calendar.listCalendars();
      if (calendars.any((Calendar calendar) => calendar.id == own)) return;
    } on Exception {
      return;
    }
    saved.removeWhere((String _, _SavedEvent e) => e.calendar == own);
    await prefs.remove(_calendarKey);
  }

  /// Deletes the app's calendar with every event on it; true when it is
  /// gone (or was already).
  Future<bool> _deleteOwnCalendar(SharedPreferences prefs) async {
    final String? own = prefs.getString(_calendarKey);
    if (own == null) return true;
    try {
      await _calendar.deleteCalendar(own);
    } on DeviceCalendarException catch (error) {
      if (error.errorCode != DeviceCalendarError.notFound) return false;
    } on Exception {
      return false;
    }
    await prefs.remove(_calendarKey);
    return true;
  }

  /// The circle and category of a key of this version, «c-1:doses»;
  /// null for an older key.
  static String? _groupOf(String key) {
    final List<String> parts = key.split(':');
    return parts.length > 3 && parts.first == _keyVersion
        ? '${parts[1]}:${parts[2]}'
        : null;
  }

  /// Whether the event of [key] repeats: everything but an appointment and
  /// a task put off.
  static bool _repeats(String key) {
    final List<String> parts = key.split(':');
    return _versioned.hasMatch(parts.first)
        ? parts.length > 3 &&
              parts[2] != CalendarSyncCategory.appointments.name &&
              parts[3] != _snoozePart
        : !key.startsWith('appointment:');
  }

  Map<String, _SavedEvent> _readSaved(SharedPreferences prefs) {
    final String? raw = prefs.getString(_eventsKey);
    if (raw == null) return <String, _SavedEvent>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, _SavedEvent>{};
      return <String, _SavedEvent>{
        for (final MapEntry<String, dynamic> entry in decoded.entries)
          if (_SavedEvent.fromJson(entry.value) case final _SavedEvent event)
            entry.key: event,
      };
    } on FormatException {
      return <String, _SavedEvent>{};
    }
  }

  Future<void> _writeSaved(
    SharedPreferences prefs,
    Map<String, _SavedEvent> saved,
  ) async {
    if (saved.isEmpty) {
      await prefs.remove(_eventsKey);
      return;
    }
    await prefs.setString(
      _eventsKey,
      jsonEncode(<String, Map<String, String>>{
        for (final MapEntry<String, _SavedEvent> entry in saved.entries)
          entry.key: entry.value.toJson(),
      }),
    );
  }

  /// Whether this app may delete events, which takes full calendar access.
  /// With add-only access (iOS), or none asked yet, it asks once per run of
  /// the app; the person turned the calendar on, so the question is theirs.
  Future<bool> _fullAccess() async {
    try {
      CalendarPermissionStatus status = await _calendar.hasPermissions();
      if (status == CalendarPermissionStatus.granted) return true;
      final bool canAsk =
          status == CalendarPermissionStatus.writeOnly ||
          status == CalendarPermissionStatus.notDetermined;
      if (!canAsk || _askedForFull) return false;
      _askedForFull = true;
      status = await _calendar.requestPermissions();
      return status == CalendarPermissionStatus.granted;
    } on Exception {
      return false;
    }
  }

  /// Makes [event] in the calendar [calendarId] (null: the phone's default
  /// one); its id, or null when it could not be made.
  Future<String?> _createEvent(_DesiredEvent event, String? calendarId) async {
    try {
      return await _calendar.createEvent(
        calendarId: calendarId,
        title: event.title,
        startDate: event.start,
        endDate: event.end,
        description: event.note,
        location: event.place,
        timeZone: event.zone,
        availability: EventAvailability.free,
        recurrenceRule: event.recurrence,
        reminders: event.reminders,
      );
    } on Exception {
      // No calendar access, or the device refused it; try again next sync.
      return null;
    }
  }

  /// Deletes the event of [key]; true when it is off the calendar (or was
  /// already), false when it should be tried again later. An event the
  /// calendar no longer knows by its id is looked for by its title at its
  /// first start; none of [known] (the ids of the other events) is taken.
  Future<bool> _delete(String key, _SavedEvent event, Set<String> known) async {
    try {
      await _deleteById(event.id, repeats: _repeats(key));
      return true;
    } on DeviceCalendarException catch (error) {
      if (error.errorCode != DeviceCalendarError.notFound) return false;
    } on Exception {
      return false;
    }
    final String? title = event.title;
    final DateTime? start = event.start;
    if (title == null || start == null) return true;
    try {
      final List<Event> found = await _calendar.listEvents(
        start,
        start.add(const Duration(minutes: 1)),
      );
      for (final Event item in found) {
        if (item.title != title || known.contains(item.eventId)) continue;
        await _deleteById(
          item.isRecurring ? item.eventId : item.instanceId,
          repeats: item.isRecurring,
        );
      }
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> _deleteById(String id, {required bool repeats}) => repeats
      ? _calendar.deleteRecurring(id, EventSpan.allEvents)
      : _calendar.deleteEvent(instanceId: id);
}

/// The last moment a repeating event that starts at [start] repeats to:
/// [ahead] (two weeks from now), or its first time when that is later, so
/// it has at least that one. UTC, as the calendar's rule takes it.
DateTime _until(DateTime start, DateTime ahead) {
  final DateTime first = start.toUtc();
  return first.isAfter(ahead) ? first : ahead;
}

DayOfWeek _dayOfWeek(int weekday) => switch (weekday) {
  1 => DayOfWeek.monday,
  2 => DayOfWeek.tuesday,
  3 => DayOfWeek.wednesday,
  4 => DayOfWeek.thursday,
  5 => DayOfWeek.friday,
  6 => DayOfWeek.saturday,
  _ => DayOfWeek.sunday,
};

/// Where a plan's events start: now, or the patient's first day of the
/// plan ([startsOn]) when it is later. A moment; [now] is the real instant.
DateTime _from(PatientClock clock, DateTime startsOn, DateTime now) {
  final DateTime first = clock.momentOf(startsOn, '00:00');
  return first.isAfter(now) ? first : now;
}

/// The first moment on/after the moment [from] that is the patient's
/// [time] («HH:mm», on [clock]) on a day of the patient's calendar where
/// [applies] — only to seed a recurring event; its rule repeats it.
/// Days are counted on the patient's calendar, so neither the phone's zone
/// nor a DST change moves one. [limit] days are looked at.
DateTime _nextOn(
  PatientClock clock,
  DateTime from,
  String time,
  int limit,
  bool Function(DateTime day) applies,
) {
  final DateTime first = clock.today(from);
  for (int i = 0; i < limit; i++) {
    final DateTime day = DateTime(first.year, first.month, first.day + i);
    final DateTime at = clock.momentOf(day, time);
    if (applies(day) && !at.isBefore(from)) return at.toLocal();
  }
  return clock.momentOf(first, time).toLocal();
}

/// The next moment on/after [from] that is [time] on one of the month
/// [days] (1 .. 28) of the patient's calendar.
DateTime _nextMonthDay(
  PatientClock clock,
  DateTime from,
  String time,
  List<int> days,
) => _nextOn(clock, from, time, 62, (DateTime day) => days.contains(day.day));

/// The first moment on/after [from] that is [time] on a day [every] days
/// apart from [startsOn], on the patient's calendar.
DateTime _nextIntervalDay(
  PatientClock clock,
  DateTime from,
  String time,
  DateTime startsOn,
  int every,
) {
  // Whole days counted on the calendar (UTC), so a clock change in between
  // does not shift the count.
  final DateTime start = DateTime.utc(
    startsOn.year,
    startsOn.month,
    startsOn.day,
  );
  return _nextOn(clock, from, time, every + 1, (DateTime day) {
    final int since = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(start).inDays;
    return since >= 0 && since % every == 0;
  });
}

/// The next moment on/after [from] that is [time] on one of [weekdays]
/// (ISO: 1 Monday .. 7 Sunday) of the patient's calendar.
DateTime _nextOccurrence(
  PatientClock clock,
  DateTime from,
  String time,
  List<int> weekdays,
) => _nextOn(
  clock,
  from,
  time,
  7,
  (DateTime day) => weekdays.contains(day.weekday),
);
