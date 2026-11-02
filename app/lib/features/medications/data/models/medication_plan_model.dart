import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';

class MedicationPlanModel {
  const MedicationPlanModel(this._entity);

  final MedicationPlan _entity;

  factory MedicationPlanModel.fromJson(Map<String, dynamic> json) {
    final versionJson = json['version'] as Map<String, dynamic>;
    final pendingJson = json['pending_version'] as Map<String, dynamic>?;
    final lastJson = json['last_record'] as Map<String, dynamic>?;
    final version = _version(versionJson);
    return MedicationPlanModel(
      MedicationPlan(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        discontinuedAt: _optionalDateTime(json['discontinued_at']),
        version: version,
        pendingVersion: pendingJson == null ? null : _version(pendingJson),
        lastRecord: lastJson == null
            ? null
            : MedicationLastRecord(
                outcome: DoseOutcome.values.byName(
                  lastJson['outcome'] as String,
                ),
                scheduledOn: DateTime.parse(lastJson['scheduled_on'] as String),
                time: lastJson['time_of_day'] as String,
                takenAt: _optionalDateTime(lastJson['taken_at']),
              ),
      ),
    );
  }

  MedicationPlan toEntity() => _entity;

  static MedicationVersion _version(Map<String, dynamic> versionJson) {
    final schedulesJson =
        versionJson['schedules'] as List<dynamic>? ?? const [];
    return MedicationVersion(
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
      missedAfterMinutes: versionJson['missed_after_minutes'] as int? ?? 60,
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
  }

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
