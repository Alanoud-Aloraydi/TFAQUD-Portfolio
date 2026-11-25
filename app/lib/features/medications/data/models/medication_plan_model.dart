import 'package:app/core/constants/plan_limits.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';

/// Maps medication plan data between the API and app.
class MedicationPlanModel {
  const MedicationPlanModel(this._entity);

  factory MedicationPlanModel.fromJson(Map<String, dynamic> json) {
    final historyJson = json['history'] as List<dynamic>? ?? const [];
    final createdBy = json['created_by'] as Map<String, dynamic>?;
    final lastEditedBy = json['last_edited_by'] as Map<String, dynamic>?;
    final pendingJson = json['pending_version'] as Map<String, dynamic>?;
    return MedicationPlanModel(
      MedicationPlan(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        discontinuedAt: optionalApiMoment(json['stopped_at']),
        version: medicationVersionFromJson(
          json['version'] as Map<String, dynamic>,
        ),
        createdByAccountId: createdBy?['account_id'] as String?,
        createdByName: createdBy?['name'] as String?,
        createdByAvatarCode: createdBy?['avatar_code'] as String?,
        lastEditedByName: lastEditedBy?['name'] as String?,
        lastEditedByAccountId: lastEditedBy?['account_id'] as String?,
        lastEditedByAvatarCode: lastEditedBy?['avatar_code'] as String?,
        pendingVersion: pendingJson == null
            ? null
            : medicationVersionFromJson(pendingJson),
        lastRecord: medicationLastRecordFromJson(
          json['last_record'] as Map<String, dynamic>?,
        ),
        history: List.unmodifiable(
          historyJson.map(
            (item) => medicationVersionFromJson(item as Map<String, dynamic>),
          ),
        ),
      ),
    );
  }

  final MedicationPlan _entity;

  MedicationPlan toEntity() => _entity;
}

/// The last dose explicitly answered, as the API sends it with the plan;
/// null when none was.
MedicationLastRecord? medicationLastRecordFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final recordedBy = json['recorded_by'] as Map<String, dynamic>?;
  return MedicationLastRecord(
    outcome: DoseOutcome.values.byName(json['outcome'] as String),
    scheduledOn: DateTime.parse(json['scheduled_on'] as String),
    time: json['time_of_day'] as String,
    takenAt: optionalApiMoment(json['taken_at']),
    skipReasonCode: json['skip_reason_code'] as String?,
    skipReasonNote: json['skip_reason_note'] as String?,
    recordedByAccountId: recordedBy?['account_id'] as String?,
    recordedByName: recordedBy?['name'] as String?,
    recordedByAvatarCode: recordedBy?['avatar_code'] as String?,
  );
}

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

/// A date the API sends without a time («YYYY-MM-DD»), or null.
DateTime? optionalApiDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// A moment the API sends in UTC, on this phone's clock, or null.
DateTime? optionalApiMoment(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toLocal();
