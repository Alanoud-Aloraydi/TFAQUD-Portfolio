import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

DoseTimingState? medicationTimingState(DoseOccurrence item, DateTime now) {
  if (item.record != null) return null;
  final parts = item.time.split(':');
  final scheduled = DateTime.utc(
    item.scheduledOn.year,
    item.scheduledOn.month,
    item.scheduledOn.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
  if (now.isBefore(scheduled)) return DoseTimingState.upcoming;
  final minutes = now.difference(scheduled).inMinutes;
  if (minutes < 15) return DoseTimingState.due;
  if (minutes < item.missedAfterMinutes) return DoseTimingState.late;
  return DoseTimingState.missed;
}
