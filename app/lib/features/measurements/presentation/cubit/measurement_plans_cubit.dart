import 'dart:async';

import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_loading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_scope.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_state.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_writing.dart';
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
