import 'package:app/core/widgets/status/plan_status.dart';
import 'package:app/features/measurements/domain/measurement.dart';

/// Reads a measurement plan's [PlanStatus] for a given day. A measurement
/// plan has no end date, so it never completes: it is stopped or it goes on.
extension MeasurementPlanStatus on MeasurementPlan {
  PlanStatus statusOn(DateTime day) {
    if (stoppedAt != null) return PlanStatus.stopped;
    if (version.effectiveFromOn.isAfter(day)) return PlanStatus.scheduled;
    return PlanStatus.active;
  }
}
