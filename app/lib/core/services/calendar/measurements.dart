part of '../calendar_sync.dart';

/// The events of the measurement times.
extension _CalendarMeasurements on _CalendarState {
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
}
