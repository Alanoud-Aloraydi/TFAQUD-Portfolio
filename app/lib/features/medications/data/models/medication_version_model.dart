import 'package:app/core/constants/plan_limits.dart';
import 'package:app/features/medications/data/models/json_dates.dart';
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

/// One dose time of a version, as the API sends it.
MedicationSchedule medicationScheduleFromJson(Map<String, dynamic> json) {
  final unit = json['dose_unit'] == 'mL'
      ? DoseUnit.milliliter
      : DoseUnit.values.byName(json['dose_unit'] as String);
  return MedicationSchedule(
    id: json['id'] as String,
    time: json['time_of_day'] as String,
    doseValue: double.parse(json['dose_value'] as String),
    doseUnit: unit,
    instructions: json['instructions'] as String?,
    weekdays: (json['weekdays'] as List<dynamic>).cast<int>(),
    // An older server sends neither: every schedule is weekly there.
    repeat: switch (json['repeat']) {
      'monthly' => ScheduleRepeat.monthly,
      'interval' => ScheduleRepeat.interval,
      _ => ScheduleRepeat.weekly,
    },
    monthDays:
        (json['month_days'] as List<dynamic>?)?.cast<int>() ?? const <int>[],
    intervalDays: json['interval_days'] as int?,
  );
}
