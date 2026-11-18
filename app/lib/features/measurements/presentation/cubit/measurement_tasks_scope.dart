import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the tasks of one circle are bound to, shared by reading them and by
/// skipping one.
mixin MeasurementTasksScope on Cubit<MeasurementTasksState> {
  MeasurementsUseCase get measurements;

  /// The circle and the patient's days read last.
  String? readCircleId;
  DateTime? readFrom;
  DateTime? readTo;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// The tasks being skipped: a second tap on one skips nothing.
  final Set<MeasurementOccurrence> skipping = {};
}
