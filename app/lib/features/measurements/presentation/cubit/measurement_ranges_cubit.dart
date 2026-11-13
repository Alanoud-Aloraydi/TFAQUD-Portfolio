import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// The normal ranges of one circle's patient, for «المعدل الطبيعي». Saving a
/// reading never waits for them: the server judges it either way.
class MeasurementRangesCubit extends Cubit<MeasurementRangesState> {
  MeasurementRangesCubit(this._repository)
    : super(const MeasurementRangesState());

  final MeasurementRepository _repository;

  /// Reads [circleId]'s ranges; called again to retry after a failure.
  Future<void> load(String circleId) async {
    emit(const MeasurementRangesState());
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
