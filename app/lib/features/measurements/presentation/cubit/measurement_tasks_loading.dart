import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
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

enum MeasurementLoadStatus { initial, loading, ready, failure }
