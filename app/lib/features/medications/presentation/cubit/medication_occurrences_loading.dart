import 'package:app/features/medications/presentation/cubit/medication_occurrences_scope.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reading the doses of a range of the patient's days.
mixin MedicationOccurrencesLoading
    on Cubit<MedicationOccurrencesState>, MedicationOccurrencesScope {
  /// Reads the doses of [circleId] from the patient's day [from] to [to]
  /// (both included, at most 32 days, as the server allows), of [planId]
  /// only when given. With [silent] the doses shown of the same circle and
  /// medicine stay while they are read again, and a failure keeps them and
  /// says nothing.
  Future<void> load(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
    bool silent = false,
  }) async {
    final bool same = this.circleId == circleId && this.planId == planId;
    this.circleId = circleId;
    this.from = from;
    this.to = to;
    this.planId = planId;
    final revision = ++this.revision;
    // A range that ends before it starts (a medicine that begins after
    // today, asked from its first day to today) holds no dose. The server
    // refuses such a range as invalid data, so it is never sent.
    if (to.isBefore(from)) {
      emit(
        MedicationOccurrencesState(status: MedicationOccurrencesStatus.ready),
      );
      return;
    }
    final bool showing =
        silent &&
        same &&
        (state.status == MedicationOccurrencesStatus.ready ||
            state.status == MedicationOccurrencesStatus.loadingMore);
    if (!showing) emit(MedicationOccurrencesState());
    final result = await medications.getOccurrences(
      circleId,
      from,
      to,
      planId: planId,
    );
    if (isClosed || revision != this.revision) return;
    result.when(
      (items) => emit(
        MedicationOccurrencesState(
          status: MedicationOccurrencesStatus.ready,
          occurrences: items,
        ),
      ),
      (failure) => emit(
        MedicationOccurrencesState(
          status: showing
              ? MedicationOccurrencesStatus.ready
              : MedicationOccurrencesStatus.failure,
          occurrences: showing ? state.occurrences : const [],
          messageKey: showing ? null : failure.messageKey,
        ),
      ),
    );
  }
}
