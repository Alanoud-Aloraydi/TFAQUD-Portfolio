/// The newest calendar day anywhere on Earth (UTC+14) at [instant] (now
/// when left out): the bound of a date with no patient yet, such as the
/// account's own birth date at onboarding. The server uses the same bound.
DateTime latestToday([DateTime? instant]) => scheduleDay(
  (instant ?? DateTime.now()).toUtc().add(const Duration(hours: 14)),
);

/// Preserves a date-only schedule value without changing its calendar day.
DateTime scheduleDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// The schedule day [days] calendar days after [day] (before it when
/// negative), as a date-only value. Calendar arithmetic, never steps of 24
/// hours: on a phone whose own zone changes its clocks, 24 hours from
/// midnight can stay on the same day.
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// The wall time of «HH:mm» [time] on the schedule [date], on the scale of
/// [PatientClock.now]. Needs no zone: it only reads the patient's clock.
DateTime wallClockAt(DateTime date, String time) {
  final parts = time.split(':');
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}
