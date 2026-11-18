import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
