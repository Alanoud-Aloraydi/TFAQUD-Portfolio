import 'package:app/features/medications/presentation/cubit/medication_occurrences_loading.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_scope.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reading the same range again: quietly after a change elsewhere, or over
/// again on purpose.
mixin MedicationOccurrencesRefresh
    on
        Cubit<MedicationOccurrencesState>,
        MedicationOccurrencesScope,
        MedicationOccurrencesLoading {
  /// A change of the circle's doses: reads the range again quietly. Not
  /// while an answer of this cubit is being saved, which updates the list
  /// itself.
  Future<void> refresh() async {
    final circleId = this.circleId;
    final from = this.from;
    final to = this.to;
    if (circleId == null ||
        from == null ||
        to == null ||
        state.status == MedicationOccurrencesStatus.recording) {
      return;
    }
    await load(circleId, from, to, planId: planId, silent: true);
  }

  /// Reads the last range again; nothing before the first load.
  Future<void> reload() async {
    if (circleId == null || from == null || to == null) return;
    await load(circleId!, from!, to!, planId: planId);
  }
}
