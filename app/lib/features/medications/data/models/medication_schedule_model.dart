import 'package:app/features/medications/domain/entities/medication_schedule.dart';

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
