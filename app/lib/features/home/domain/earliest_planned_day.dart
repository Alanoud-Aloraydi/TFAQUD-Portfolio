import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';

/// The first day anything was planned: where «السجل كاملًا» starts. Null
/// when nothing was.
DateTime? earliestPlannedDay(
  List<MedicationPlan> plans,
  List<MeasurementPlan> measurementPlans,
) {
  final dates = <DateTime>[
    for (final plan in plans) plan.version.startsOn,
    for (final plan in measurementPlans)
      if (plan.history.isNotEmpty) plan.history.first.effectiveFromOn,
  ]..sort();
  return dates.firstOrNull;
}
