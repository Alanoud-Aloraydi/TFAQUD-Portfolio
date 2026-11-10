import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// Where an unrecorded dose stands at [now], the patient's wall time
/// ([PatientClock.now]); null once recorded.
DoseTimingState? medicationTimingState(DoseOccurrence item, DateTime now) {
  if (item.record != null) return null;
  final scheduled = wallClockAt(item.scheduledOn, item.time);
  if (now.isBefore(scheduled)) return DoseTimingState.upcoming;
  final minutes = now.difference(scheduled).inMinutes;
  if (minutes < 15) return DoseTimingState.due;
  if (minutes < item.missedAfterMinutes) return DoseTimingState.late;
  return DoseTimingState.missed;
}

/// Identifies an unresolved dose eligible for the next-task card.
bool medicationIsNextTaskCandidate(DoseOccurrence item, DateTime now) {
  final status = medicationTimingState(item, now);
  if (status == DoseTimingState.due || status == DoseTimingState.late) {
    return item.scheduledOn.year == now.year &&
        item.scheduledOn.month == now.month &&
        item.scheduledOn.day == now.day;
  }
  return status == DoseTimingState.upcoming;
}
