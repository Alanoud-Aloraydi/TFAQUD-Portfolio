import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The measurement plans of one circle, and their changes.
///
/// The «الخطة» tab holds one; the plan form page holds its own. Each reads
/// again whenever the use case says the circle's plans changed, wherever
/// the change was saved, so the two never disagree.
class MeasurementPlansCubit extends Cubit<MeasurementPlansState> {
  MeasurementPlansCubit(this._measurements)
    : super(const MeasurementPlansState()) {
    _changes = _measurements.changes.listen((circleId) {
      if (circleId == _circleId) unawaited(load(circleId, silent: true));
    });
  }

  final MeasurementsUseCase _measurements;
  late final StreamSubscription<String> _changes;
  String? _circleId;

  /// Goes up at each [load], so an older reading that ends later is dropped.
  int _revision = 0;

  /// True while a plan is being saved: a second tap saves nothing.
  bool _writing = false;

  /// Reads [circleId]'s plans; the list of another circle is cleared first.
  /// With [silent] a list already shown stays while it is read again (no
  /// loading state), and a failure keeps it.
  Future<void> load(String circleId, {bool silent = false}) async {
    final changedCircle = _circleId != circleId;
    _circleId = circleId;
    final revision = ++_revision;
    final bool keep =
        silent && !changedCircle && state.status == MeasurementLoadStatus.ready;
    if (!keep) {
      emit(
        MeasurementPlansState(
          status: MeasurementLoadStatus.loading,
          plans: changedCircle ? const [] : state.plans,
        ),
      );
    }
    try {
      final plans = await _measurements.plans(circleId);
      if (isClosed || revision != _revision) return;
      emit(
        MeasurementPlansState(
          status: MeasurementLoadStatus.ready,
          plans: plans,
        ),
      );
    } catch (error) {
      if (isClosed || revision != _revision) return;
      emit(
        MeasurementPlansState(
          status: keep
              ? MeasurementLoadStatus.ready
              : MeasurementLoadStatus.failure,
          plans: state.plans,
          errorKey: keep
              ? null
              : FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }

  /// Adds a plan; null when saved, else the message key to show.
  Future<String?> create(MeasurementPlanDraft draft) =>
      _write((circleId) => _measurements.createPlan(circleId, draft));

  /// Changes [plan] (its latest version); null when saved, else the
  /// message key to show.
  Future<String?> revise(MeasurementPlan plan, MeasurementPlanDraft draft) =>
      _write((circleId) => _measurements.revisePlan(circleId, plan, draft));

  /// Stops [plan]; null when stopped, else the message key to show.
  Future<String?> stop(MeasurementPlan plan) =>
      _write((circleId) => _measurements.stopPlan(circleId, plan.id));

  /// A saved change reloads through the use case's changes. A plan
  /// changed or gone elsewhere (conflict, not found) reads the plans again
  /// so the page shows the truth.
  Future<String?> _write(
    Future<MeasurementPlan> Function(String circleId) operation,
  ) async {
    final circleId = _circleId;
    if (circleId == null || _writing) return null;
    _writing = true;
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
      _writing = false;
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
