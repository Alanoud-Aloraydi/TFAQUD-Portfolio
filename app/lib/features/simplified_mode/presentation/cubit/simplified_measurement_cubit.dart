import 'package:app/core/errors/failure.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Loads what «تسجيل قياس» needs and saves one reading.
class SimplifiedMeasurementCubit extends Cubit<SimplifiedMeasurementState> {
  SimplifiedMeasurementCubit(
    this._useCase,
    this._circleId, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(SimplifiedMeasurementState());

  final SimplifiedModeUseCase _useCase;
  final String _circleId;
  final DateTime Function() _clock;

  Future<void> load() async {
    emit(SimplifiedMeasurementState());
    final result = await _useCase.measurementOptions(_circleId, _clock());
    if (isClosed) return;
    result.when(
      (options) => emit(
        SimplifiedMeasurementState(
          status: SimplifiedMeasurementStatus.ready,
          targets: options.$1,
          occurrences: options.$2,
        ),
      ),
      (Failure failure) => emit(
        SimplifiedMeasurementState(
          status: SimplifiedMeasurementStatus.failure,
          messageKey: failure.messageKey,
        ),
      ),
    );
  }

  /// Saves [reading] against today's task of its kind when one is waiting,
  /// else as a free reading. Returns whether it was saved.
  Future<bool> save(SimplifiedReading reading) async {
    if (state.saving || !reading.isValid) return false;
    emit(state.copyWith(saving: true, clearMessage: true));
    final DateTime now = _clock();
    final MeasurementOccurrence? task = state.taskFor(reading.kind, now);
    final Result<MeasurementReading, Failure> result = await _useCase
        .recordMeasurement(
          _circleId,
          MeasurementReadingDraft(
            kind: reading.kind,
            outcome: 'read',
            measuredAt: now,
            valueOne: reading.valueOne,
            valueTwo: reading.valueTwo,
            conditions: reading.conditions,
            note: reading.note,
          ),
          occurrence: task,
        );
    if (isClosed) return result.isSuccess();
    final Failure? failure = result.tryGetError();
    emit(state.copyWith(saving: false, messageKey: failure?.messageKey));
    return failure == null;
  }
}
