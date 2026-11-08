import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Loads what the simplified measurement screens need in one call, and
/// saves a glucose or blood-pressure reading — against today's task when
/// one is due or missed, otherwise as a free reading.
@injectable
class SimplifiedMeasurementCubit extends Cubit<SimplifiedMeasurementState> {
  SimplifiedMeasurementCubit(this._repository)
    : super(const SimplifiedMeasurementState());

  final MeasurementRepository _repository;
  String? _circleId;

  Future<void> load(String circleId) async {
    _circleId = circleId;
    emit(const SimplifiedMeasurementState());
    final DateTime today = riyadhToday();
    try {
      final results = await (
        _repository.targets(circleId),
        _repository.occurrences(circleId, today, today),
      ).wait;
      emit(
        SimplifiedMeasurementState(
          status: SimplifiedMeasurementStatus.ready,
          targets: results.$1,
          occurrences: results.$2,
        ),
      );
    } catch (error) {
      emit(
        SimplifiedMeasurementState(
          status: SimplifiedMeasurementStatus.failure,
          errorKey: FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }

  /// Saves a one-reading glucose value. Returns whether it was saved.
  Future<bool> recordGlucose(int value) {
    final MeasurementTarget? target = state.targetFor(MeasurementKind.glucose);
    final MeasurementOccurrence? occurrence = state.occurrenceFor(
      MeasurementKind.glucose,
    );
    final bool needsFreeTarget = occurrence == null && target?.planId == null;
    return _record(
      occurrence: occurrence,
      draft: MeasurementReadingDraft(
        kind: MeasurementKind.glucose,
        outcome: 'read',
        measuredAt: DateTime.now(),
        valueOne: value,
        // A planned reading keeps its plan's «ظروف القياس».
        conditions: occurrence?.conditions ?? const <String>[],
        glucoseLow: needsFreeTarget ? target?.glucoseLow : null,
        glucoseHigh: needsFreeTarget ? target?.glucoseHigh : null,
      ),
    );
  }

  /// Saves a blood-pressure reading. Returns whether it was saved.
  Future<bool> recordBp(int systolic, int diastolic) {
    final MeasurementTarget? target = state.targetFor(MeasurementKind.bp);
    final MeasurementOccurrence? occurrence = state.occurrenceFor(
      MeasurementKind.bp,
    );
    final bool needsFreeTarget = occurrence == null && target?.planId == null;
    return _record(
      occurrence: occurrence,
      draft: MeasurementReadingDraft(
        kind: MeasurementKind.bp,
        outcome: 'read',
        measuredAt: DateTime.now(),
        valueOne: systolic,
        valueTwo: diastolic,
        conditions: occurrence?.conditions ?? const <String>[],
        systolicLimit: needsFreeTarget ? target?.systolicLimit : null,
        diastolicLimit: needsFreeTarget ? target?.diastolicLimit : null,
      ),
    );
  }

  Future<bool> _record({
    required MeasurementReadingDraft draft,
    MeasurementOccurrence? occurrence,
  }) async {
    final String? circleId = _circleId;
    if (circleId == null) return false;
    emit(
      SimplifiedMeasurementState(
        status: state.status,
        targets: state.targets,
        occurrences: state.occurrences,
        saveStatus: SimplifiedMeasurementSaveStatus.saving,
      ),
    );
    try {
      await _repository.record(circleId, draft, occurrence: occurrence);
      if (isClosed) return true;
      emit(
        SimplifiedMeasurementState(
          status: state.status,
          targets: state.targets,
          occurrences: state.occurrences,
        ),
      );
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          SimplifiedMeasurementState(
            status: state.status,
            targets: state.targets,
            occurrences: state.occurrences,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
      return false;
    }
  }
}
