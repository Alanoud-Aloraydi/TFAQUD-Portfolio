/// Returns the current Riyadh wall time for schedules stored without a zone.
DateTime riyadhNow([DateTime? instant]) =>
    (instant ?? DateTime.now()).toUtc().add(const Duration(hours: 3));

/// Returns the Riyadh calendar day as a date-only value.
DateTime riyadhToday([DateTime? instant]) {
  final now = riyadhNow(instant);
  return scheduleDay(now);
}

/// Preserves a date-only schedule value without changing its calendar day.
DateTime scheduleDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// Combines a schedule date and HH:mm time on the same wall-time scale.
DateTime riyadhScheduledAt(DateTime date, String time) {
  final parts = time.split(':');
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}
