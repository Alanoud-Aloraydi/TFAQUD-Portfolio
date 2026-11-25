import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the tasks of a range of the patient's days, and reads them again.
mixin MeasurementTasksLoading
    on Cubit<MeasurementTasksState>, MeasurementTasksScope {
  /// Reads an exact patient-calendar range for read-only history views.
  Future<void> loadRange(
    String circleId,
    DateTime from,
    DateTime to, {
    bool silent = false,
  }) async {
    final changedQuery =
        readCircleId != circleId || readFrom != from || readTo != to;
    readCircleId = circleId;
    readFrom = from;
    readTo = to;
    final revision = ++this.revision;
    final bool keep =
        silent && !changedQuery && state.status == MeasurementLoadStatus.ready;
    if (!keep) {
      emit(
        MeasurementTasksState(
          status: MeasurementLoadStatus.loading,
          tasks: changedQuery ? const [] : state.tasks,
        ),
      );
    }
    try {
      final tasks = await measurements.occurrences(circleId, from, to);
      if (isClosed || revision != this.revision) return;
      emit(
        MeasurementTasksState(
          status: MeasurementLoadStatus.ready,
          tasks: tasks,
        ),
      );
    } catch (error) {
      if (isClosed || revision != this.revision) return;
      emit(
        MeasurementTasksState(
          status: keep
              ? MeasurementLoadStatus.ready
              : MeasurementLoadStatus.failure,
          tasks: state.tasks,
          errorKey: keep
              ? null
              : FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }

  /// Reads the last load again, quietly: what is shown stays meanwhile.
  Future<void> reload() async {
    if (readCircleId != null && readFrom != null && readTo != null) {
      await loadRange(readCircleId!, readFrom!, readTo!, silent: true);
    }
  }
}

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
