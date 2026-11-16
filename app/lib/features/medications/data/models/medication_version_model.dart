import 'package:app/core/constants/plan_limits.dart';
import 'package:app/features/medications/data/models/json_dates.dart';
import 'package:app/features/medications/data/models/medication_schedule_model.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';

/// One version of a medicine, as the API sends it: what it was, for how
/// long, and the dose times it had.
MedicationVersion medicationVersionFromJson(Map<String, dynamic> json) {
  final schedulesJson = json['schedules'] as List<dynamic>? ?? const [];
  return MedicationVersion(
    number: json['version_number'] as int,
    name: json['name'] as String,
    strengthValue: double.parse(json['strength_value'] as String),
    strengthUnit: StrengthUnit.fromApi(json['strength_unit'] as String),
    dosageForm: DosageForm.values.byName(json['dosage_form'] as String),
    reason: json['reason_for_use'] as String?,
    instructions: json['instructions'] as String?,
    missedAfterMinutes:
        json['missed_after_minutes'] as int? ??
        PlanLimits.defaultMissedAfterMinutes,
    startsOn: DateTime.parse(json['treatment_starts_on'] as String),
    endsOn: optionalApiDate(json['treatment_ends_on']),
    effectiveFromOn: DateTime.parse(json['effective_from_on'] as String),
    effectiveUntilOn: optionalApiDate(json['effective_until_on']),
    schedules: schedulesJson
        .map((item) => medicationScheduleFromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
