import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The normal ranges of one circle's patient, for «المعدل الطبيعي». Saving a
/// reading never waits for them: the server judges it either way.
class MeasurementRangesCubit extends Cubit<MeasurementRangesState> {
  MeasurementRangesCubit(this._repository)
    : super(const MeasurementRangesState());

  final MeasurementsRepository _repository;

  /// Reads [circleId]'s ranges; called again to retry after a failure.
  /// [quiet] keeps the ranges on screen while the new ones load.
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

/// Holds the normal ranges of one patient while they load.
class MeasurementRangesState extends Equatable {
  const MeasurementRangesState({
    this.loading = true,
    this.ranges,
    this.errorKey,
  });

  final bool loading;

  /// Null until read, or when reading failed.
  final NormalRanges? ranges;
  final String? errorKey;

  @override
  List<Object?> get props => [loading, ranges, errorKey];
}
