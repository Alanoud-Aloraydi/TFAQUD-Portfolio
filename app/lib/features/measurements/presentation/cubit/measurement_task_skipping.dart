import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_scope.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «تخطي» on a task.
mixin MeasurementTaskSkipping
    on Cubit<MeasurementTasksState>, MeasurementTasksScope {
  /// «تخطي» on [occurrence], the task the person chose. Null when skipped
  /// (the list reads again through the use case), else the message key
  /// to show; a second tap while it saves is ignored (null).
  Future<String?> skip(
    MeasurementOccurrence occurrence,
    MeasurementReadingDraft draft,
  ) async {
    final circleId = readCircleId;
    if (circleId == null || !skipping.add(occurrence)) return null;
    try {
      await measurements.record(circleId, draft, occurrence: occurrence);
      return null;
    } catch (error) {
      return FailureExceptions.getException(error).messageKey;
    } finally {
      skipping.remove(occurrence);
    }
  }
}
