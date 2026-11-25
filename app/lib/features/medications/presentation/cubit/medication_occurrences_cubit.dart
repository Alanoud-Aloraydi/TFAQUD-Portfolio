import 'dart:async';

import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_loading.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_recording.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_scope.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The doses of one range of the patient's days, and their recording.
///
/// The «اليوم» tab holds one for the selected circle (the overdue days to a
/// month ahead); a medicine's details page holds one for that plan's history.
/// Widgets call [load], [loadEarlier] and [record]/[take]; the cubit asks
/// [MedicationsUseCase] (→ repository → `GET medication-occurrences` and
/// `PUT medication-dose-records`). Each cubit reads its range again, with no
/// loading state, whenever [MedicationsUseCase.changes] says the circle's
/// medicines or dose records changed, wherever that was saved, so the tab and
/// a medicine's page never disagree. Its own saved answer is put in the list
/// directly, never read again.
class MedicationOccurrencesCubit extends Cubit<MedicationOccurrencesState>
    with
        MedicationOccurrencesScope,
        MedicationOccurrencesLoading,
        MedicationOccurrencesRefresh,
        MedicationOccurrencesEarlier,
        MedicationOccurrencesRecording,
        MedicationOccurrencesTaking {
  /// [photoChanges] reloads the doses when a photo or avatar changes
  /// anywhere (who recorded a dose shows theirs). [clock] is the real
  /// moment now, for a dose taken now; tests give their own.
  MedicationOccurrencesCubit(
    this.medications, {
    this._photoChanges,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now,
       super(MedicationOccurrencesState()) {
    _photoChanges?.addListener(_onPhotoChanged);
    _changes = medications.changes.listen((circleId) {
      // This cubit's own saved answer: the list already shows it.
      if (ownSaves.remove(circleId)) return;
      if (circleId == this.circleId) unawaited(refresh());
    });
  }

  @override
  final MedicationsUseCase medications;

  @override
  final DateTime Function() clock;

  final Listenable? _photoChanges;
  late final StreamSubscription<String> _changes;

  // Quietly: the doses stay on screen while they are read again.
  void _onPhotoChanged() => unawaited(refresh());

  @override
  Future<void> close() async {
    _photoChanges?.removeListener(_onPhotoChanged);
    await _changes.cancel();
    return super.close();
  }
}

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
