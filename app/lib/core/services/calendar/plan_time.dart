part of '../calendar_sync.dart';

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
