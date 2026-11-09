import 'dart:async';
import 'dart:convert';

import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/medications/domain/dose_reminders.dart'
    show ReminderCircle;
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:easy_localization/easy_localization.dart';
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
    this.note,
    this.place,
    this.recurrence,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final List<Duration> reminders;
  final String? note;
  final String? place;
  final RecurrenceRule? recurrence;
}

/// What this phone remembers of an event it made: the calendar's id for
/// it, and its title and first start, to find it again when the calendar
/// gave it another id (a calendar of another account can, once it syncs).
/// An event saved before this version has its id only.
class _SavedEvent {
  const _SavedEvent(this.id, {this.title, this.start});

  final String id;
  final String? title;
  final DateTime? start;

  static _SavedEvent? fromJson(Object? value) {
    if (value is String) return _SavedEvent(value);
    if (value is! Map<String, dynamic>) return null;
    final Object? id = value['id'];
    final Object? title = value['title'];
    final Object? start = value['start'];
    if (id is! String) return null;
    return _SavedEvent(
      id,
      title: title is String ? title : null,
      start: start is String ? DateTime.tryParse(start) : null,
    );
  }

  Map<String, String> toJson() => <String, String>{
    'id': id,
    'title': ?title,
    'start': ?start?.toIso8601String(),
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
/// Nothing here is stored on the server. Each phone keeps its own small map
/// of "key it created" → "calendar event" in [SharedPreferences], and on
/// every [refresh] recomputes the full desired set from the plans and
/// appointments the signed-in person can see, deleting what is no longer
/// wanted and creating what is missing — the same reconcile-from-scratch
/// shape as [ReminderCircle]'s own local notifications, so an edited or
/// discontinued plan is picked up automatically, never left stale. An event
/// the calendar would not delete yet (no full access, say) stays in the map
/// and is deleted at a later refresh.
class CalendarSync {
  CalendarSync(
    this._medications,
    this._measurements,
    this._appointments, {
    DeviceCalendar? calendar,
    CalendarEventTexts? texts,
  }) : _calendar = calendar ?? DeviceCalendar.instance,
       _texts = texts ?? calendarEventTexts {
    // Any accepted plan or appointment change reconciles the calendar right
    // away, not just on the next app resume.
    _medications.changes.listen((_) => unawaited(refresh()));
    _measurements.changes.listen((_) => unawaited(refresh()));
    _appointments.changes.listen((_) => unawaited(refresh()));
  }

  final MedicationsUseCase _medications;
  final MeasurementRepository _measurements;
  final AppointmentRepository _appointments;
  final DeviceCalendar _calendar;
  final CalendarEventTexts _texts;

  static const String _selectionsKey = 'calendar_sync_selections';
  static const String _eventsKey = 'calendar_sync_events';

  /// What the keys of this version start with. A key of an older version
  /// (an older wording) is not wanted any more, so its event is replaced.
  static const String _keyVersion = 'v2';

  List<ReminderCircle> _circles = const <ReminderCircle>[];

  /// Whether [sync] gave the circles yet. Before it, a refresh would find no
  /// circle and delete every event, to make them again a moment later.
  bool _synced = false;
  Future<void>? _running;
  bool _again = false;
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

  /// Removes every event this feature made: the person signed out. Also
  /// clears every selection — they are stored on the device, not the
  /// account, so the next person to sign in on this device must opt in
  /// themselves. An event the calendar would not delete now is deleted at
  /// the next refresh.
  Future<void> clear() async {
    _session++;
    _circles = const <ReminderCircle>[];
    _synced = false;
    _again = false;
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
    if (session != _session) return;
    await _reconcile(prefs, desired, unread, session);
  }

  Future<bool> _collectDoses(
    ReminderCircle circle,
    Map<String, _DesiredEvent> desired,
  ) async {
    final result = await _medications.getPlans(circle.id);
    final plans = result.tryGetSuccess();
    if (plans == null) return false;
    final DateTime now = DateTime.now();
    for (final plan in plans) {
      if (plan.isPreviousOn(now)) continue;
      final version = plan.version;
      final DateTime from = version.effectiveFromOn.isAfter(now)
          ? version.effectiveFromOn
          : now;
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
            start = _nextMonthDay(from, schedule.time, days);
            recurrence = MonthlyRecurrence(daysOfMonth: days);
          // A dose every few days as one event repeating every that many
          // days («FREQ=DAILY;INTERVAL=3»), from its first day on or after
          // [from] on the count from the start of the treatment.
          case ScheduleRepeat.interval:
            final int? every = schedule.intervalDays;
            if (every == null || every < 1) continue;
            start = _nextIntervalDay(
              from,
              schedule.time,
              version.startsOn,
              every,
            );
            recurrence = DailyRecurrence(interval: every);
          case ScheduleRepeat.weekly:
            start = _nextOccurrence(from, schedule.time, schedule.weekdays);
            recurrence = WeeklyRecurrence(
              daysOfWeek: schedule.weekdays.map(_dayOfWeek).toList(),
            );
        }
        desired[key] = _DesiredEvent(
          title: title,
          note: _texts.doseNote(),
          start: start,
          end: start.add(const Duration(minutes: 15)),
          reminders: const <Duration>[Duration.zero],
          recurrence: recurrence,
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
    final DateTime now = DateTime.now();
    for (final plan in plans) {
      if (plan.stoppedAt != null) continue;
      final version = plan.version;
      final DateTime from = version.effectiveFromOn.isAfter(now)
          ? version.effectiveFromOn
          : now;
      // One event per reading time.
      final List<MeasurementTime> readings = version.readingTimes;
      for (int index = 0; index < readings.length; index++) {
        final DateTime start = _nextOccurrence(
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
          start: start,
          end: start.add(const Duration(minutes: 15)),
          reminders: const <Duration>[Duration.zero],
          recurrence: WeeklyRecurrence(
            daysOfWeek: version.weekdays.map(_dayOfWeek).toList(),
          ),
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
    final DateTime now = DateTime.now();
    for (final appointment in appointments) {
      if (appointment.status != AppointmentStatus.scheduled) continue;
      // The same people as its reminders: the patient and those going.
      if (!circle.remindsOfAppointment(appointment.companionIds)) continue;
      // Built from the wall-clock fields directly (not [scheduledAt], which
      // is tagged UTC for ordering elsewhere) so the device's own calendar
      // shows it at the intended local time.
      final DateTime at = _wallClock(appointment.scheduledOn, appointment.time);
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
    // Not wanted any more, or wanted with other words: taken off.
    final List<String> stale = <String>[];
    for (final MapEntry<String, _SavedEvent> entry in saved.entries) {
      final _DesiredEvent? wanted = desired[entry.key];
      if (wanted != null
          ? wanted.title != entry.value.title
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
    for (final MapEntry<String, _DesiredEvent> entry in desired.entries) {
      if (session != _session) return;
      // Still there: its old event could not be taken off yet.
      if (saved.containsKey(entry.key)) continue;
      final String? id = await _createEvent(entry.value);
      if (id != null) {
        saved[entry.key] = _SavedEvent(
          id,
          title: entry.value.title,
          start: entry.value.start,
        );
      }
    }
    if (session != _session) return;
    await _writeSaved(prefs, saved);
  }

  Future<void> _removeAll(SharedPreferences prefs) async {
    final Map<String, _SavedEvent> saved = _readSaved(prefs);
    if (saved.isNotEmpty && await _fullAccess()) {
      final Set<String> known = <String>{
        for (final _SavedEvent event in saved.values) event.id,
      };
      for (final String key in saved.keys.toList()) {
        if (await _delete(key, saved[key]!, known)) saved.remove(key);
      }
    }
    await _writeSaved(prefs, saved);
  }

  /// The circle and category of a key of this version, «c-1:doses»;
  /// null for an older key.
  static String? _groupOf(String key) {
    final List<String> parts = key.split(':');
    return parts.length > 3 && parts.first == _keyVersion
        ? '${parts[1]}:${parts[2]}'
        : null;
  }

  /// Whether the event of [key] repeats: everything but an appointment.
  static bool _repeats(String key) {
    final List<String> parts = key.split(':');
    return parts.first == _keyVersion
        ? parts.length > 2 && parts[2] != CalendarSyncCategory.appointments.name
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

  Future<String?> _createEvent(_DesiredEvent event) async {
    try {
      return await _calendar.createEvent(
        title: event.title,
        startDate: event.start,
        endDate: event.end,
        description: event.note,
        location: event.place,
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

DayOfWeek _dayOfWeek(int weekday) => switch (weekday) {
  1 => DayOfWeek.monday,
  2 => DayOfWeek.tuesday,
  3 => DayOfWeek.wednesday,
  4 => DayOfWeek.thursday,
  5 => DayOfWeek.friday,
  6 => DayOfWeek.saturday,
  _ => DayOfWeek.sunday,
};

/// The next moment on/after [from] that is [time] ("HH:mm") on one of the
/// month [days] (1 .. 28) — only to seed a recurring event; the monthly
/// rule itself repeats it.
DateTime _nextMonthDay(DateTime from, String time, List<int> days) {
  final List<String> parts = time.split(':');
  final int hour = int.parse(parts[0]);
  final int minute = int.parse(parts[1]);
  for (int i = 0; i < 62; i++) {
    final DateTime day = DateTime(
      from.year,
      from.month,
      from.day + i,
      hour,
      minute,
    );
    if (days.contains(day.day) && !day.isBefore(from)) return day;
  }
  return DateTime(from.year, from.month, from.day, hour, minute);
}

/// The first moment on/after [from] that is [time] ("HH:mm") on a day
/// [every] days apart from [startsOn] — only to seed a recurring event.
DateTime _nextIntervalDay(
  DateTime from,
  String time,
  DateTime startsOn,
  int every,
) {
  final DateTime first = _wallClock(startsOn, time);
  if (!first.isBefore(from)) return first;
  // Whole days between the dates, counted on the calendar (UTC), so a
  // clock change in between does not shift the count.
  final int since = DateTime.utc(from.year, from.month, from.day)
      .difference(DateTime.utc(startsOn.year, startsOn.month, startsOn.day))
      .inDays;
  final int ahead = (every - since % every) % every;
  final DateTime day = _wallClock(
    DateTime(from.year, from.month, from.day + ahead),
    time,
  );
  return day.isBefore(from)
      ? _wallClock(DateTime(day.year, day.month, day.day + every), time)
      : day;
}

/// [date] and [time] ("HH:mm") as a plain local [DateTime], not tagged UTC.
DateTime _wallClock(DateTime date, String time) {
  final List<String> parts = time.split(':');
  return DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

/// The next moment on/after [from] that is [time] ("HH:mm") on one of
/// [weekdays] (ISO: 1 Monday .. 7 Sunday) — only to seed a recurring event;
/// the weekly rule itself repeats it.
DateTime _nextOccurrence(DateTime from, String time, List<int> weekdays) {
  final List<String> parts = time.split(':');
  final int hour = int.parse(parts[0]);
  final int minute = int.parse(parts[1]);
  for (int i = 0; i < 7; i++) {
    final DateTime day = DateTime(
      from.year,
      from.month,
      from.day + i,
      hour,
      minute,
    );
    if (weekdays.contains(day.weekday) && !day.isBefore(from)) return day;
  }
  return DateTime(from.year, from.month, from.day, hour, minute);
}
