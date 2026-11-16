import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_load_status.dart';
import 'package:equatable/equatable.dart';

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
