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

  /// Readies the form, then the last readings behind it: fixed normal
  /// ranges judge every reading and a free one needs no target, so the
  /// form is ready at once and the history never holds it up. A history
  /// that cannot be read is simply not shown.
  Future<void> load() async {
    emit(
      SimplifiedMeasurementState(
        task: state.task,
        status: SimplifiedMeasurementStatus.ready,
      ),
    );
    List<MeasurementReading> recent;
    try {
      recent = await _useCase.recentReadings(_circleId, _clock());
    } on Exception {
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(recent: recent));
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
            otherCondition: reading.note,
          ),
          occurrence: state.task,
        );
    if (isClosed) return result.isSuccess();
    final Failure? failure = result.tryGetError();
    emit(
      state.copyWith(
        saving: false,
        messageKey: failure?.messageKey,
        saved: result.tryGetSuccess(),
      ),
    );
    return failure == null;
  }
}
