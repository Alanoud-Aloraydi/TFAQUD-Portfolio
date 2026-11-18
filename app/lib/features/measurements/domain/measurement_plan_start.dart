import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/measurements/domain/measurement_version.dart';

/// Where a plan began.
extension MeasurementPlanStart on MeasurementPlan {
  /// The first day of the plan: its earliest version's (an edit starts a
  /// later version).
  DateTime get startsOn => <MeasurementVersion>[version, ...history]
      .map((MeasurementVersion item) => item.effectiveFromOn)
      .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
}
