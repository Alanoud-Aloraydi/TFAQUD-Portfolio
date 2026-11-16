/// A scheduled occurrence (dose, measurement) can be recorded starting one
/// hour before its scheduled time, never earlier — the same rule across
/// every domain shown on «اليوم». Both values are wall times.
bool isRecordableNow(DateTime scheduledAt, DateTime now) =>
    !now.isBefore(scheduledAt.subtract(const Duration(hours: 1)));

/// One rule, shared by every domain on «اليوم»: a row offers its record
/// controls only while it is not already resolved, and not more than an
/// hour before its scheduled time.
bool canRecordOccurrence({
  required bool resolved,
  required DateTime scheduledAt,
  required DateTime now,
}) => !resolved && isRecordableNow(scheduledAt, now);
