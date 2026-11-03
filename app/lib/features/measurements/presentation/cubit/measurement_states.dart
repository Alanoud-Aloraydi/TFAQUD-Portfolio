import 'package:app/features/measurements/domain/measurement.dart';
import 'package:equatable/equatable.dart';

enum MeasurementLoadStatus { initial, loading, ready, failure }

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

class MeasurementReadingsState extends Equatable {
  const MeasurementReadingsState({
    this.status = MeasurementLoadStatus.initial,
    this.readings = const [],
    this.errorKey,
  });

  final MeasurementLoadStatus status;
  final List<MeasurementReading> readings;
  final String? errorKey;

  @override
  List<Object?> get props => [status, readings, errorKey];
}
