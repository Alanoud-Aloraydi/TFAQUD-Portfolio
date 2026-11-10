import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the measurement targets presentation state.
class MeasurementTargetsState extends Equatable {
  MeasurementTargetsState({
    this.loading = true,
    List<MeasurementTarget> targets = const [],
    this.errorKey,
  }) : targets = List.unmodifiable(targets);

  final bool loading;
  final List<MeasurementTarget> targets;
  final String? errorKey;

  @override
  List<Object?> get props => [loading, targets, errorKey];
}

/// The targets of one circle's patient, for a free reading's sheet.
class MeasurementTargetsCubit extends Cubit<MeasurementTargetsState> {
  MeasurementTargetsCubit(this._repository) : super(MeasurementTargetsState());

  final MeasurementRepository _repository;

  /// Reads [circleId]'s targets; called again to retry after a failure.
  Future<void> load(String circleId) async {
    emit(MeasurementTargetsState());
    try {
      final targets = await _repository.targets(circleId);
      if (!isClosed) {
        emit(MeasurementTargetsState(loading: false, targets: targets));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          MeasurementTargetsState(
            loading: false,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
    }
  }
}
