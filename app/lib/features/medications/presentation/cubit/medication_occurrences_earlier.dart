import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_scope.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «أقدم»: reading the days before the range already shown.
mixin MedicationOccurrencesEarlier
    on Cubit<MedicationOccurrencesState>, MedicationOccurrencesScope {
  /// Whether days before the range read so far are still to be read, down
  /// to [earliest] (the medicine's first day).
  bool canLoadEarlier(DateTime earliest) =>
      from != null && earliest.isBefore(from!);

  /// Reads up to 32 more days before the range, not before [earliest], and
  /// puts them first. A failure keeps the doses shown and sets
  /// [MedicationOccurrencesState.messageKey].
  Future<void> loadEarlier(DateTime earliest) async {
    final circleId = this.circleId;
    final currentFrom = from;
    if (circleId == null ||
        currentFrom == null ||
        !earliest.isBefore(currentFrom)) {
      return;
    }
    // Calendar days, not 24-hour steps: on a phone whose own zone changes
    // its clocks, a step of 24 hours from midnight can stay on one day.
    final to = addDays(currentFrom, -1);
    final candidate = addDays(currentFrom, -32);
    final start = candidate.isBefore(earliest) ? earliest : candidate;
    final revision = ++this.revision;
    emit(
      MedicationOccurrencesState(
        status: MedicationOccurrencesStatus.loadingMore,
        occurrences: state.occurrences,
      ),
    );
    final result = await medications.getOccurrences(
      circleId,
      start,
      to,
      planId: planId,
    );
    if (isClosed || revision != this.revision) return;
    result.when(
      (items) {
        from = start;
        emit(
          MedicationOccurrencesState(
            status: MedicationOccurrencesStatus.ready,
            occurrences: [...items, ...state.occurrences],
          ),
        );
      },
      (failure) => emit(
        MedicationOccurrencesState(
          status: MedicationOccurrencesStatus.ready,
          occurrences: state.occurrences,
          messageKey: failure.messageKey,
        ),
      ),
    );
  }
}
