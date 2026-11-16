import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// Groups medication occurrences by prayer period.
class MedicationPeriodSummary {
  MedicationPeriodSummary(List<DoseOccurrence> occurrences, DateTime now) {
    attentionCount = occurrences.where((item) {
      final status = medicationTimingState(item, now);
      return status == DoseTimingState.late || status == DoseTimingState.missed;
    }).length;
    hasMissed = occurrences.any(
      (item) => medicationTimingState(item, now) == DoseTimingState.missed,
    );
    allResolved =
        occurrences.isNotEmpty &&
        occurrences.every(
          (item) =>
              item.record != null ||
              medicationTimingState(item, now) == DoseTimingState.missed,
        );
  }

  late final int attentionCount;
  late final bool hasMissed;
  late final bool allResolved;
}
