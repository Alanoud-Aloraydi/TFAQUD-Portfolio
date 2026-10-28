import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';

class MedicationPlanModel {
  const MedicationPlanModel(this._entity);

  final MedicationPlan _entity;

  factory MedicationPlanModel.fromJson(Map<String, dynamic> json) {
    final versionJson = json['version'] as Map<String, dynamic>;
    final schedulesJson =
        versionJson['schedules'] as List<dynamic>? ?? const [];
    final version = MedicationVersion(
      number: versionJson['version_number'] as int,
      name: versionJson['name'] as String,
      strengthValue: double.parse(versionJson['strength_value'] as String),
      strengthUnit: StrengthUnit.fromApi(
        versionJson['strength_unit'] as String,
      ),
      dosageForm: DosageForm.values.byName(
        versionJson['dosage_form'] as String,
      ),
      reason: versionJson['reason_for_use'] as String?,
      instructions: versionJson['instructions'] as String?,
      startsOn: DateTime.parse(versionJson['treatment_starts_on'] as String),
      endsOn: _optionalDate(versionJson['treatment_ends_on']),
      effectiveFromOn: DateTime.parse(
        versionJson['effective_from_on'] as String,
      ),
      effectiveUntilOn: _optionalDate(versionJson['effective_until_on']),
      schedules: schedulesJson
          .map((item) => _schedule(item as Map<String, dynamic>))
          .toList(),
    );
    return MedicationPlanModel(
      MedicationPlan(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        discontinuedAt: _optionalDateTime(json['discontinued_at']),
        version: version,
      ),
    );
  }

  MedicationPlan toEntity() => _entity;

  static MedicationSchedule _schedule(Map<String, dynamic> json) {
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
    );
  }

  static DateTime? _optionalDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  static DateTime? _optionalDateTime(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();
}
