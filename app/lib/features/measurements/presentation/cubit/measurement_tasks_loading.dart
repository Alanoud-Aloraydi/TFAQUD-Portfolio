import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_load_status.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_scope.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_state.dart';
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
