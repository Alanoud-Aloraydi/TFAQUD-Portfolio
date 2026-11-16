import 'package:app/features/medications/data/models/json_dates.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';

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
