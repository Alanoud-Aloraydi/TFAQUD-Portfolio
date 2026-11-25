import 'dart:async';

import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
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
