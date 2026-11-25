import 'package:app/features/home/domain/entities/export_period.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
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

/// The name of the exported file: «`tafaqod-<patient>-<from>-<to>.pdf`», with
/// only letters and digits (Arabic or Latin) so every share target accepts it.
String exportFilename(String? patientName, ExportPeriod period) {
  final String safe = (patientName ?? 'record').trim().replaceAll(
    RegExp(r'[^A-Za-z0-9؀-ۿ]+'),
    '-',
  );
  return 'tafaqod-$safe-${_day(period.start)}-${_day(period.end)}.pdf';
}

String _day(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
