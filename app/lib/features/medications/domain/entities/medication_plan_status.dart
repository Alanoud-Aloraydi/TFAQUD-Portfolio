import 'package:app/core/widgets/status/plan_status.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';

/// Reads a medication plan's [PlanStatus] for a given day.
extension MedicationPlanStatus on MedicationPlan {
  PlanStatus statusOn(DateTime day) {
    if (discontinuedAt != null) return PlanStatus.stopped;
    if (isPreviousOn(day)) return PlanStatus.completed;
    if (isScheduledOn(day)) return PlanStatus.scheduled;
    return PlanStatus.active;
  }
}
