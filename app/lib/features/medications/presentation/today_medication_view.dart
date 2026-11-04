import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/dose_timing.dart';

/// Selects medication occurrences for the Today view.
class TodayMedicationView {
  TodayMedicationView(List<DoseOccurrence> occurrences, DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    todayOccurrences =
        occurrences
            .where(
              (item) =>
                  item.scheduledOn.year == today.year &&
                  item.scheduledOn.month == today.month &&
                  item.scheduledOn.day == today.day,
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    next = todayOccurrences.where((item) {
      final status = medicationTimingState(item, now);
      return status == DoseTimingState.upcoming ||
          status == DoseTimingState.due ||
          status == DoseTimingState.late;
    }).firstOrNull;
    attention =
        occurrences.where((item) {
          final status = medicationTimingState(item, now);
          final scheduledOn = DateTime.utc(
            item.scheduledOn.year,
            item.scheduledOn.month,
            item.scheduledOn.day,
          );
          return item != next &&
              !scheduledOn.isAfter(today) &&
              item.record == null &&
              (status == DoseTimingState.late ||
                  status == DoseTimingState.missed);
        }).toList()..sort((a, b) {
          final byDate = b.scheduledOn.compareTo(a.scheduledOn);
          return byDate != 0 ? byDate : a.time.compareTo(b.time);
        });
  }

  late final List<DoseOccurrence> todayOccurrences;
  late final DoseOccurrence? next;
  late final List<DoseOccurrence> attention;
}

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
