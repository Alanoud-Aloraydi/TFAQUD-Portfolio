import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';

/// Identifies an unrecorded measurement eligible for the next-task card,
/// by the same rule as a dose in `dose_timing.dart`: one still
/// to come always counts, and one whose time has passed counts only today
/// and only until its deadline, after which «يحتاج انتباهك» carries it.
///
/// The server's status is read once; the deadline it sends keeps the answer
/// right after that, the way «جدول اليوم» reads it.
bool measurementIsNextTaskCandidate(MeasurementOccurrence item, DateTime now) {
  if (item.record != null) return false;
  if (item.status != MeasurementStatus.upcoming &&
      item.status != MeasurementStatus.due) {
    return false;
  }
  if (now.isBefore(wallClockAt(item.scheduledOn, item.time))) return true;
  if (now.isAfter(item.deadlineAt)) return false;
  return item.scheduledOn.year == now.year &&
      item.scheduledOn.month == now.month &&
      item.scheduledOn.day == now.day;
}
