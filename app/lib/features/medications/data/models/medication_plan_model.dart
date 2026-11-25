import 'package:app/features/medications/data/models/json_dates.dart';
import 'package:app/features/medications/data/models/medication_version_model.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';

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
