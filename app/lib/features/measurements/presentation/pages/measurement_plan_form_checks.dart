import 'package:app/core/constants/plan_limits.dart';
import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_scope.dart';

/// What the plan form checks before it saves.
mixin MeasurementPlanFormChecks on MeasurementPlanFormScope {
  /// The active plan of the kind shown among [plans], when there is one.
  MeasurementPlan? activePlanOf(List<MeasurementPlan> plans) {
    for (final item in plans) {
      if (item.kind == kind && item.stoppedAt == null) return item;
    }
    return null;
  }

  /// Whether the form can be saved; when not, shows why and says false.
  bool isReady(MeasurementPlan? plan) {
    if (days.isEmpty) {
      setState(() => errorKey = 'measurements.days_required');
      return false;
    }
    if (!PlanLimits.isValidMissedAfter(missedAfter)) {
      setState(() => missedAfterChecked = true);
      return false;
    }
    final times = <String>{for (final item in readings) item.clock};
    if (times.length != readings.length) {
      setState(() => errorKey = 'measurements.times_repeat');
      return false;
    }
    return true;
  }
}
