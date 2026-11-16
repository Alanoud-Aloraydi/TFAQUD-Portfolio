part of '../calendar_sync.dart';

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
