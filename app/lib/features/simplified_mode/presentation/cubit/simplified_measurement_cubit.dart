import 'package:app/core/errors/failure.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Loads what «تسجيل قياس» needs and saves one reading: against [task]
/// when the screen was opened for one, else as a free reading.
class SimplifiedMeasurementCubit extends Cubit<SimplifiedMeasurementState> {
  SimplifiedMeasurementCubit(
    this._useCase,
    this._circleId, {
    MeasurementOccurrence? task,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(SimplifiedMeasurementState(task: task));

  final SimplifiedModeUseCase _useCase;
  final String _circleId;
  final DateTime Function() _clock;

  Future<void> load() async {
    emit(SimplifiedMeasurementState(task: state.task));
    final result = await _useCase.measurementTargets(_circleId);
    if (isClosed) return;
    result.when(
      (targets) => emit(
        state.copyWith(
          status: SimplifiedMeasurementStatus.ready,
          targets: targets,
        ),
      ),
      (Failure failure) => emit(
        state.copyWith(
          status: SimplifiedMeasurementStatus.failure,
          messageKey: failure.messageKey,
        ),
      ),
    );
  }

  /// Saves [reading]. Returns whether it was saved.
  Future<bool> save(SimplifiedReading reading) async {
    if (state.saving || !reading.isValid) return false;
    emit(state.copyWith(saving: true, clearMessage: true));
    final Result<MeasurementReading, Failure> result = await _useCase
        .recordMeasurement(
          _circleId,
          MeasurementReadingDraft(
            kind: reading.kind,
            outcome: 'read',
            measuredAt: _clock(),
            valueOne: reading.valueOne,
            valueTwo: reading.valueTwo,
            conditions: reading.conditions,
            note: reading.note,
          ),
          occurrence: state.task,
        );
    if (isClosed) return result.isSuccess();
    final Failure? failure = result.tryGetError();
    emit(state.copyWith(saving: false, messageKey: failure?.messageKey));
    return failure == null;
  }
}
