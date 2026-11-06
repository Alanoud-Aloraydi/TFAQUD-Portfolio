import 'dart:async';
import 'dart:convert';

import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/medications/domain/dose_reminders.dart' show ReminderCircle;
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One kind of event this feature can mirror, switched on per circle.
enum CalendarSyncCategory { doses, measurements, appointments }

/// One event this feature wants on the phone's calendar, before it exists.
class _DesiredEvent {
  const _DesiredEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.reminders,
    this.recurrence,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final List<Duration> reminders;
  final RecurrenceRule? recurrence;
}

/// Mirrors active medication and measurement schedules, and upcoming
/// appointments, onto the phone's own Calendar app — a backup to the push
/// and local-notification reminders, for a dose that must not be missed.
///
/// Opt-in ([setEnabled]), off by default, and chosen per circle and per
/// category: someone in several circles may want only one circle's
/// appointments on their calendar, say. A dose or appointment written into
/// the phone's shared calendar is visible to anything else with calendar
/// access, unlike the rest of this app's circle-scoped data.
///
/// Nothing here is stored on the server. Each phone keeps its own small map
/// of "key it created" → "calendar event id" in [SharedPreferences], and on
/// every [refresh] recomputes the full desired set from the plans and
/// appointments the signed-in person can see, deleting what is no longer
/// wanted and creating what is missing — the same reconcile-from-scratch
/// shape as [ReminderCircle]'s own local notifications, so an edited or
/// discontinued plan is picked up automatically, never left stale.
class CalendarSync {
  CalendarSync(this._medications, this._measurements, this._appointments) {
    // Any accepted plan or appointment change reconciles the calendar right
    // away, not just on the next app resume.
    _medications.changes.listen((_) => unawaited(refresh()));
    _measurements.changes.listen((_) => unawaited(refresh()));
    _appointments.changes.listen((_) => unawaited(refresh()));
  }

  final MedicationsUseCase _medications;
  final MeasurementRepository _measurements;
  final AppointmentRepository _appointments;

  final DeviceCalendar _calendar = DeviceCalendar.instance;

  static const String _selectionsKey = 'calendar_sync_selections';
  static const String _eventsKey = 'calendar_sync_events';

  List<ReminderCircle> _circles = const <ReminderCircle>[];
  Future<void>? _running;
  bool _again = false;
  int _session = 0;

  String _selectionKey(String circleId, CalendarSyncCategory category) =>
      '$circleId:${category.name}';

  Future<Set<String>> _selections(SharedPreferences prefs) async =>
      (prefs.getStringList(_selectionsKey) ?? const <String>[]).toSet();

  /// Whether this circle's category is turned on.
  Future<bool> isEnabled(String circleId, CalendarSyncCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    return selections.contains(_selectionKey(circleId, category));
  }

  /// Turns one circle's category on or off; [refresh] reconciles the
  /// calendar to match every selection right after.
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
  /// themselves.
  Future<void> clear() async {
    _session++;
    _circles = const <ReminderCircle>[];
    _again = false;
    final prefs = await SharedPreferences.getInstance();
    await _removeAll(prefs);
    await prefs.remove(_selectionsKey);
  }

  Future<void> _run() async {
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    final int session = _session;
    final List<ReminderCircle> circles = _circles;
    final Map<String, _DesiredEvent> desired = <String, _DesiredEvent>{};
    for (final ReminderCircle circle in circles) {
      if (session != _session) return;
      if (selections.contains(
        _selectionKey(circle.id, CalendarSyncCategory.doses),
      )) {
        await _collectDoses(circle, desired);
      }
      if (session != _session) return;
      if (selections.contains(
        _selectionKey(circle.id, CalendarSyncCategory.measurements),
      )) {
        await _collectMeasurements(circle, desired);
      }
      if (session != _session) return;
      if (selections.contains(
        _selectionKey(circle.id, CalendarSyncCategory.appointments),
      )) {
        await _collectAppointments(circle, desired);
      }
    }
    if (session != _session) return;
    await _reconcile(prefs, desired);
  }

  Future<void> _collectDoses(
    ReminderCircle circle,
    Map<String, _DesiredEvent> desired,
  ) async {
    final result = await _medications.getPlans(circle.id);
    final plans = result.tryGetSuccess();
    if (plans == null) return;
    final DateTime now = DateTime.now();
    for (final plan in plans) {
      if (plan.isPreviousOn(now)) continue;
      final version = plan.version;
      final DateTime from = version.effectiveFromOn.isAfter(now)
          ? version.effectiveFromOn
          : now;
      for (final MedicationSchedule schedule in version.schedules) {
        final DateTime start = _nextOccurrence(
          from,
          schedule.time,
          schedule.weekdays,
        );
        desired['dose:${schedule.id}'] = _DesiredEvent(
          title: '${circle.name} · ${version.name}',
          start: start,
          end: start.add(const Duration(minutes: 15)),
          reminders: const <Duration>[Duration.zero],
          recurrence: WeeklyRecurrence(
            daysOfWeek: schedule.weekdays.map(_dayOfWeek).toList(),
          ),
        );
      }
    }
  }

  Future<void> _collectMeasurements(
    ReminderCircle circle,
    Map<String, _DesiredEvent> desired,
  ) async {
    final List<MeasurementPlan> plans;
    try {
      plans = await _measurements.plans(circle.id);
    } on Exception {
      return;
    }
    final DateTime now = DateTime.now();
    for (final plan in plans) {
      if (plan.stoppedAt != null) continue;
      final version = plan.version;
      final DateTime from = version.effectiveFromOn.isAfter(now)
          ? version.effectiveFromOn
          : now;
      final DateTime start = _nextOccurrence(from, version.time, version.weekdays);
      final String kindName = plan.kind == MeasurementKind.glucose
          ? 'قياس سكر الدم'
          : 'قياس ضغط الدم';
      desired['measurement:${version.id}'] = _DesiredEvent(
        title: '${circle.name} · $kindName',
        start: start,
        end: start.add(const Duration(minutes: 15)),
        reminders: const <Duration>[Duration.zero],
        recurrence: WeeklyRecurrence(
          daysOfWeek: version.weekdays.map(_dayOfWeek).toList(),
        ),
      );
    }
  }

  Future<void> _collectAppointments(
    ReminderCircle circle,
    Map<String, _DesiredEvent> desired,
  ) async {
    final List<CareAppointment> appointments;
    try {
      appointments = await _appointments.appointments(circle.id);
    } on Exception {
      return;
    }
    final DateTime now = DateTime.now();
    for (final appointment in appointments) {
      if (appointment.status != AppointmentStatus.scheduled) continue;
      // Built from the wall-clock fields directly (not [scheduledAt], which
      // is tagged UTC for ordering elsewhere) so the device's own calendar
      // shows it at the intended local time.
      final DateTime at = _wallClock(appointment.scheduledOn, appointment.time);
      if (at.isBefore(now)) continue;
      // The date and time are part of the key: an edited appointment gets a
      // new key, so the stale event is deleted and a fresh one created,
      // rather than silently keeping the old time.
      final key =
          'appointment:${appointment.id}:'
          '${appointment.scheduledOn.toIso8601String()}:${appointment.time}';
      desired[key] = _DesiredEvent(
        title: '${circle.name} · ${appointment.specialty}',
        start: at,
        end: at.add(const Duration(hours: 1)),
        reminders: const <Duration>[Duration(hours: 24), Duration.zero],
      );
    }
  }

  Future<void> _reconcile(
    SharedPreferences prefs,
    Map<String, _DesiredEvent> desired,
  ) async {
    final Map<String, String> saved = _readSaved(prefs);
    for (final String key in saved.keys.toList()) {
      if (!desired.containsKey(key)) {
        await _deleteEvent(key, saved[key]!);
        saved.remove(key);
      }
    }
    for (final MapEntry<String, _DesiredEvent> entry in desired.entries) {
      if (saved.containsKey(entry.key)) continue;
      final String? id = await _createEvent(entry.value);
      if (id != null) saved[entry.key] = id;
    }
    await prefs.setString(_eventsKey, jsonEncode(saved));
  }

  Future<void> _removeAll(SharedPreferences prefs) async {
    final Map<String, String> saved = _readSaved(prefs);
    for (final MapEntry<String, String> entry in saved.entries) {
      await _deleteEvent(entry.key, entry.value);
    }
    await prefs.remove(_eventsKey);
  }

  Map<String, String> _readSaved(SharedPreferences prefs) {
    final String? raw = prefs.getString(_eventsKey);
    if (raw == null) return <String, String>{};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).cast<String, String>();
    } on FormatException {
      return <String, String>{};
    }
  }

  Future<String?> _createEvent(_DesiredEvent event) async {
    try {
      return await _calendar.createEvent(
        title: event.title,
        startDate: event.start,
        endDate: event.end,
        availability: EventAvailability.free,
        recurrenceRule: event.recurrence,
        reminders: event.reminders,
      );
    } on Exception {
      // No calendar access, or the device refused it; try again next sync.
      return null;
    }
  }

  Future<void> _deleteEvent(String key, String eventId) async {
    try {
      if (key.startsWith('appointment:')) {
        await _calendar.deleteEvent(instanceId: eventId);
      } else {
        await _calendar.deleteRecurring(eventId, EventSpan.allEvents);
      }
    } on Exception {
      // Already gone, or access was revoked; drop it from bookkeeping anyway.
    }
  }
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
    final DateTime day = DateTime(from.year, from.month, from.day + i, hour, minute);
    if (weekdays.contains(day.weekday) && !day.isBefore(from)) return day;
  }
  return DateTime(from.year, from.month, from.day, hour, minute);
}
