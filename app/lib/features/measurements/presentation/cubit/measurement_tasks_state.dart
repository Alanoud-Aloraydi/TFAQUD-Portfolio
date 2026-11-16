import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_load_status.dart';
import 'package:equatable/equatable.dart';

/// The day's measurement tasks on screen.
class MeasurementTasksState extends Equatable {
  const MeasurementTasksState({
    this.status = MeasurementLoadStatus.initial,
    this.tasks = const [],
    this.errorKey,
  });

  final MeasurementLoadStatus status;
  final List<MeasurementOccurrence> tasks;
  final String? errorKey;

  @override
  List<Object?> get props => [status, tasks, errorKey];
}
