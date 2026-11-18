import 'package:app/features/measurements/domain/measurement_plan.dart';

/// The condition a plan names for itself.
extension MeasurementPlanCondition on MeasurementPlan {
  /// The «حالة القياس» of the plan's only reading time; none when it has
  /// several, each of which has its own.
  String? get singleCondition => version.readingTimes.length == 1
      ? version.readingTimes.single.measurementState
      : null;
}
