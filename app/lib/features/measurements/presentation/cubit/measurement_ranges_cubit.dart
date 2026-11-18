import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/domain/repositories/measurement_repository.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_range_condition.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The normal ranges of one circle's patient, for «المعدل الطبيعي». Saving a
/// reading never waits for them: the server judges it either way.
class MeasurementRangesCubit extends Cubit<MeasurementRangesState>
    with MeasurementRangeCondition {
  MeasurementRangesCubit(this._repository, [this.circles])
    : super(const MeasurementRangesState());

  final MeasurementRepository _repository;

  @override
  final CirclesUseCase? circles;

  /// Reads [circleId]'s ranges; called again to retry after a failure.
  /// [quiet] keeps the ranges on screen while the new ones load.
  @override
  Future<void> load(String circleId, {bool quiet = false}) async {
    if (!quiet || state.ranges == null) emit(const MeasurementRangesState());
    try {
      final NormalRanges ranges = await _repository.ranges(circleId);
      if (!isClosed) {
        emit(MeasurementRangesState(loading: false, ranges: ranges));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          MeasurementRangesState(
            loading: false,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
    }
  }
}
