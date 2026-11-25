import 'dart:async';

import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_loading.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_scope.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Writing a dose's answer: the one the person gave, and what the server
/// says about it.
mixin MedicationOccurrencesRecording
    on
        Cubit<MedicationOccurrencesState>,
        MedicationOccurrencesScope,
        MedicationOccurrencesRefresh {
  /// Saves [record] for [occurrence] (the dose the person answered, never
  /// another one). Returns null when saved, else the message key to show.
  ///
  /// A dose answered differently elsewhere (conflict) or no longer in its
  /// plan (not found) reads the range again, so the list shows the truth.
  /// While one dose is saving, another answer is ignored (null).
  Future<String?> record(
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) async {
    final circleId = this.circleId;
    if (circleId == null ||
        state.status == MedicationOccurrencesStatus.recording) {
      return null;
    }
    emit(
      MedicationOccurrencesState(
        status: MedicationOccurrencesStatus.recording,
        occurrences: state.occurrences,
        recordingOccurrence: occurrence,
      ),
    );
    final revision = this.revision;
    ownSaves.add(circleId);
    final result = await medications.recordDose(circleId, occurrence, record);
    // Refused: no change is announced for it.
    if (result.isError()) ownSaves.remove(circleId);
    // A reading started meanwhile replaces the list with the server's,
    // which already has this answer if it was saved.
    if (isClosed || revision != this.revision) return null;
    return result.when(
      (saved) {
        emit(
          MedicationOccurrencesState(
            status: MedicationOccurrencesStatus.ready,
            occurrences: withSavedRecord(state.occurrences, occurrence, saved),
          ),
        );
        return null;
      },
      (failure) {
        emit(
          MedicationOccurrencesState(
            status: MedicationOccurrencesStatus.ready,
            occurrences: state.occurrences,
          ),
        );
        if (isStaleDose(failure)) unawaited(reload());
        return doseRefusalKey(failure);
      },
    );
  }
}

/// The doses with the saved answer in place of the one that was asked
/// about. A dose is the schedule and the day together, so a medicine with
/// two times a day keeps them apart.
List<DoseOccurrence> withSavedRecord(
  List<DoseOccurrence> occurrences,
  DoseOccurrence answered,
  DoseRecord saved,
) => <DoseOccurrence>[
  for (final item in occurrences)
    if (item.scheduleId == answered.scheduleId &&
        item.scheduledOn == answered.scheduledOn)
      item.withRecord(saved)
    else
      item,
];

/// Whether the refusal means the list is behind: the dose was answered
/// elsewhere, or it is no longer in its plan.
bool isStaleDose(Failure failure) =>
    failure is ConflictFailure || failure is NotFoundFailure;

/// What to say about a refused answer: a dose that is gone says so in its
/// own words, anything else in the failure's.
String? doseRefusalKey(Failure failure) =>
    failure is NotFoundFailure ? 'medications.dose_gone' : failure.messageKey;
