import 'package:app/features/medications/data/models/json_dates.dart';
import 'package:app/features/medications/data/models/medication_last_record_model.dart';
import 'package:app/features/medications/data/models/medication_version_model.dart';
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
