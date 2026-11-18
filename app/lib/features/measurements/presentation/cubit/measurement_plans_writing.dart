import 'dart:async';

import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/errors/network_failures.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_scope.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adds, changes and stops a plan.
mixin MeasurementPlansWriting
    on Cubit<MeasurementPlansState>, MeasurementPlansScope {
  /// Adds a plan; null when saved, else the message key to show.
  Future<String?> create(MeasurementPlanDraft draft) =>
      _write((circleId) => measurements.createPlan(circleId, draft));

  /// Changes [plan] (its latest version); null when saved, else the
  /// message key to show.
  Future<String?> revise(MeasurementPlan plan, MeasurementPlanDraft draft) =>
      _write((circleId) => measurements.revisePlan(circleId, plan, draft));

  /// Stops [plan]; null when stopped, else the message key to show.
  Future<String?> stop(MeasurementPlan plan) =>
      _write((circleId) => measurements.stopPlan(circleId, plan.id));

  /// A saved change reloads through the use case's changes. A plan
  /// changed or gone elsewhere (conflict, not found) reads the plans again
  /// so the page shows the truth.
  Future<String?> _write(
    Future<MeasurementPlan> Function(String circleId) operation,
  ) async {
    final circleId = readCircleId;
    if (circleId == null || writing) return null;
    writing = true;
    try {
      await operation(circleId);
      return null;
    } catch (error) {
      final Failure failure = FailureExceptions.getException(error);
      if (!isClosed &&
          (failure is ConflictFailure || failure is NotFoundFailure)) {
        unawaited(load(circleId));
      }
      return failure.messageKey;
    } finally {
      writing = false;
    }
  }
}
