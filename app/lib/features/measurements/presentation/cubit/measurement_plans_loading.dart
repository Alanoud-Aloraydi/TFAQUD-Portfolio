import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the plans of a circle.
mixin MeasurementPlansLoading
    on Cubit<MeasurementPlansState>, MeasurementPlansScope {
  /// Reads [circleId]'s plans; the list of another circle is cleared first.
  /// With [silent] a list already shown stays while it is read again (no
  /// loading state), and a failure keeps it.
  @override
  Future<void> load(String circleId, {bool silent = false}) async {
    final changedCircle = readCircleId != circleId;
    readCircleId = circleId;
    final revision = ++this.revision;
    final bool keep =
        silent && !changedCircle && state.status == MeasurementLoadStatus.ready;
    if (!keep) {
      emit(
        MeasurementPlansState(
          status: MeasurementLoadStatus.loading,
          plans: changedCircle ? const [] : state.plans,
        ),
      );
    }
    try {
      final plans = await measurements.plans(circleId);
      if (isClosed || revision != this.revision) return;
      emit(
        MeasurementPlansState(
          status: MeasurementLoadStatus.ready,
          plans: plans,
        ),
      );
    } catch (error) {
      if (isClosed || revision != this.revision) return;
      emit(
        MeasurementPlansState(
          status: keep
              ? MeasurementLoadStatus.ready
              : MeasurementLoadStatus.failure,
          plans: state.plans,
          errorKey: keep
              ? null
              : FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }
}

/// The plans on screen, and whether one is being saved.
class MeasurementPlansState extends Equatable {
  const MeasurementPlansState({
    this.status = MeasurementLoadStatus.initial,
    this.plans = const [],
    this.errorKey,
  });

  final MeasurementLoadStatus status;
  final List<MeasurementPlan> plans;
  final String? errorKey;

  @override
  List<Object?> get props => [status, plans, errorKey];
}
