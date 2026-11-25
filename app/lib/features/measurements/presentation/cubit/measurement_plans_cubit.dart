import 'dart:async';

import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The measurement plans of one circle, and their changes.
///
/// The «الخطة» tab holds one; the plan form page holds its own. Each reads
/// again whenever the use case says the circle's plans changed, wherever
/// the change was saved, so the two never disagree.
class MeasurementPlansCubit extends Cubit<MeasurementPlansState>
    with
        MeasurementPlansScope,
        MeasurementPlansLoading,
        MeasurementPlansWriting {
  MeasurementPlansCubit(this.measurements)
    : super(const MeasurementPlansState()) {
    _changes = measurements.changes.listen((circleId) {
      if (circleId == readCircleId) unawaited(load(circleId, silent: true));
    });
  }

  @override
  final MeasurementsUseCase measurements;
  late final StreamSubscription<String> _changes;

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}

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

/// What the plans of one circle are bound to, shared by reading them and
/// by changing them.
mixin MeasurementPlansScope on Cubit<MeasurementPlansState> {
  MeasurementsUseCase get measurements;

  /// The circle read last.
  String? readCircleId;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// True while a plan is being saved: a second tap saves nothing.
  bool writing = false;

  /// Reads [circleId]'s plans; [silent] keeps a list already shown.
  Future<void> load(String circleId, {bool silent = false});
}
