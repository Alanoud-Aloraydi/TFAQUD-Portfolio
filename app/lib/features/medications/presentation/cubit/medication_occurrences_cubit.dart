import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The doses of one range of the patient's days, and their recording.
///
/// The «اليوم» tab holds one for the selected circle (yesterday to a month
/// ahead); a medicine's details page holds one for that plan's history.
/// Widgets call [load], [loadEarlier] and [record]/[take]; the cubit asks
/// [MedicationsUseCase] (→ repository → `GET medication-occurrences` and
/// `PUT medication-dose-records`). Each cubit reads its range again, with no
/// loading state, whenever [MedicationsUseCase.changes] says the circle's
/// medicines or dose records changed, wherever that was saved, so the tab and
/// a medicine's page never disagree. Its own saved answer is put in the list
/// directly, never read again.
class MedicationOccurrencesCubit extends Cubit<MedicationOccurrencesState> {
  /// [photoChanges] reloads the doses when a photo or avatar changes
  /// anywhere (who recorded a dose shows theirs). [clock] is the real
  /// moment now, for a dose taken now; tests give their own.
  MedicationOccurrencesCubit(
    this._medications, {
    this._photoChanges,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(MedicationOccurrencesState()) {
    _photoChanges?.addListener(_onPhotoChanged);
    _changes = _medications.changes.listen((circleId) {
      // This cubit's own saved answer: the list already shows it.
      if (_ownSaves.remove(circleId)) return;
      if (circleId == _circleId) unawaited(_refresh());
    });
  }

  final MedicationsUseCase _medications;
  final Listenable? _photoChanges;
  final DateTime Function() _clock;
  late final StreamSubscription<String> _changes;
  String? _circleId;
  DateTime? _from;
  DateTime? _to;
  String? _planId;

  /// The circles of this cubit's answers being saved, one entry each. The
  /// use case announces each accepted answer on its changes, whenever that
  /// reaches the listener, and that announcement is not read again.
  final List<String> _ownSaves = <String>[];

  /// Goes up at each [load] and [loadEarlier], so an older reading that
  /// ends later is dropped.
  int _revision = 0;

  void _onPhotoChanged() => unawaited(reload());

  @override
  Future<void> close() async {
    _photoChanges?.removeListener(_onPhotoChanged);
    await _changes.cancel();
    return super.close();
  }

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
    final bool same = _circleId == circleId && _planId == planId;
    _circleId = circleId;
    _from = from;
    _to = to;
    _planId = planId;
    final revision = ++_revision;
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
    final result = await _medications.getOccurrences(
      circleId,
      from,
      to,
      planId: planId,
    );
    if (isClosed || revision != _revision) return;
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

  /// A change of the circle's doses: reads the range again quietly. Not
  /// while an answer of this cubit is being saved, which updates the list
  /// itself.
  Future<void> _refresh() async {
    final circleId = _circleId;
    final from = _from;
    final to = _to;
    if (circleId == null ||
        from == null ||
        to == null ||
        state.status == MedicationOccurrencesStatus.recording) {
      return;
    }
    await load(circleId, from, to, planId: _planId, silent: true);
  }

  /// Reads the last range again; nothing before the first [load].
  Future<void> reload() async {
    if (_circleId == null || _from == null || _to == null) return;
    await load(_circleId!, _from!, _to!, planId: _planId);
  }

  /// Whether days before the range read so far are still to be read, down
  /// to [earliest] (the medicine's first day).
  bool canLoadEarlier(DateTime earliest) =>
      _from != null && earliest.isBefore(_from!);

  /// Reads up to 32 more days before the range, not before [earliest], and
  /// puts them first. A failure keeps the doses shown and sets
  /// [MedicationOccurrencesState.messageKey].
  Future<void> loadEarlier(DateTime earliest) async {
    final circleId = _circleId;
    final currentFrom = _from;
    if (circleId == null ||
        currentFrom == null ||
        !earliest.isBefore(currentFrom)) {
      return;
    }
    // Calendar days, not 24-hour steps: on a phone whose own zone changes
    // its clocks, a step of 24 hours from midnight can stay on one day.
    final to = addDays(currentFrom, -1);
    final candidate = addDays(currentFrom, -32);
    final from = candidate.isBefore(earliest) ? earliest : candidate;
    final revision = ++_revision;
    emit(
      MedicationOccurrencesState(
        status: MedicationOccurrencesStatus.loadingMore,
        occurrences: state.occurrences,
      ),
    );
    final result = await _medications.getOccurrences(
      circleId,
      from,
      to,
      planId: _planId,
    );
    if (isClosed || revision != _revision) return;
    result.when(
      (items) {
        _from = from;
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

  /// «انأخذت» on [occurrence]: taken now, or at [takenAt] (a real moment)
  /// when the time was picked. A picked time still to come is refused here
  /// with its message, as the server would.
  Future<String?> take(DoseOccurrence occurrence, [DateTime? takenAt]) {
    final DateTime now = _clock();
    if (takenAt != null && takenAt.isAfter(now)) {
      return Future<String?>.value('medications.future_taken_time');
    }
    return record(
      occurrence,
      DoseRecordDraft(outcome: DoseOutcome.taken, takenAt: takenAt ?? now),
    );
  }

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
    final circleId = _circleId;
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
    final revision = _revision;
    _ownSaves.add(circleId);
    final result = await _medications.recordDose(circleId, occurrence, record);
    // Refused: no change is announced for it.
    if (result.isError()) _ownSaves.remove(circleId);
    // A reading started meanwhile replaces the list with the server's,
    // which already has this answer if it was saved.
    if (isClosed || revision != _revision) return null;
    return result.when(
      (saved) {
        emit(
          MedicationOccurrencesState(
            status: MedicationOccurrencesStatus.ready,
            occurrences: [
              for (final item in state.occurrences)
                if (item.scheduleId == occurrence.scheduleId &&
                    item.scheduledOn == occurrence.scheduledOn)
                  item.withRecord(saved)
                else
                  item,
            ],
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
        final bool stale =
            failure is ConflictFailure || failure is NotFoundFailure;
        if (stale) unawaited(reload());
        return failure is NotFoundFailure
            ? 'medications.dose_gone'
            : failure.messageKey;
      },
    );
  }
}
