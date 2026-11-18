import 'dart:async';

import 'package:app/core/utils/overdue_window.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_task_skipping.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_scope.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_state.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The measurement tasks of one circle, from the patient's day to a month
/// ahead, and «تخطي» on one.
///
/// Reads again whenever the use case says the circle's plans changed or
/// one of its tasks was answered (here, in a reading sheet, or elsewhere
/// as the server said), so no screen has to reload it by hand.
class MeasurementTasksCubit extends Cubit<MeasurementTasksState>
    with
        MeasurementTasksScope,
        MeasurementTasksLoading,
        MeasurementTaskSkipping {
  /// [photoChanges] reloads the tasks when a photo or avatar changes
  /// anywhere (who recorded a measurement shows theirs).
  MeasurementTasksCubit(this.measurements, [Listenable? photoChanges])
    : _photoChanges = photoChanges,
      super(const MeasurementTasksState()) {
    _photoChanges?.addListener(_onPhotoChanged);
    _subscriptions = [
      measurements.changes.listen(_onCircleChanged),
      measurements.recorded.listen(_onCircleChanged),
    ];
  }

  @override
  final MeasurementsUseCase measurements;
  final Listenable? _photoChanges;
  late final List<StreamSubscription<String>> _subscriptions;

  void _onPhotoChanged() => unawaited(reload());

  void _onCircleChanged(String circleId) {
    if (circleId == readCircleId) unawaited(reload());
  }

  @override
  Future<void> close() async {
    _photoChanges?.removeListener(_onPhotoChanged);
    for (final StreamSubscription<String> item in _subscriptions) {
      await item.cancel();
    }
    return super.close();
  }

  /// Reads [circleId]'s tasks from the first overdue day before the
  /// patient's [day] to 30 calendar days later, so «يحتاج انتباهك» keeps an
  /// unrecorded task until its last overdue day.
  /// With [silent] a list already shown stays while it is read again (no
  /// loading state), and a failure keeps it.
  Future<void> load(String circleId, DateTime day, {bool silent = false}) =>
      loadRange(
        circleId,
        overdueStart(day),
        DateTime(day.year, day.month, day.day + 30),
        silent: silent,
      );
}
