import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_recording.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_scope.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «تم أخذها»: a dose taken now, or at a time the person picked.
mixin MedicationOccurrencesTaking
    on
        Cubit<MedicationOccurrencesState>,
        MedicationOccurrencesScope,
        MedicationOccurrencesRecording {
  /// «تم أخذها» on [occurrence]: taken now, or at [takenAt] (a real moment)
  /// when the time was picked. A picked time still to come is refused here
  /// with its message, as the server would.
  Future<String?> take(DoseOccurrence occurrence, [DateTime? takenAt]) {
    final DateTime now = clock();
    if (takenAt != null && takenAt.isAfter(now)) {
      return Future<String?>.value('medications.future_taken_time');
    }
    return record(
      occurrence,
      DoseRecordDraft(outcome: DoseOutcome.taken, takenAt: takenAt ?? now),
    );
  }
}
