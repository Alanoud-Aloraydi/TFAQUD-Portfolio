import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';

/// Maps dose occurrence data between the API and app.
class DoseOccurrenceModel {
  const DoseOccurrenceModel(this._entity);

  final DoseOccurrence _entity;

  factory DoseOccurrenceModel.fromJson(Map<String, dynamic> json) {
    final recordJson = json['record'] as Map<String, dynamic>?;
    final unit = json['dose_unit'] == 'mL'
        ? DoseUnit.milliliter
        : DoseUnit.values.byName(json['dose_unit'] as String);
    return DoseOccurrenceModel(
      DoseOccurrence(
        planId: json['plan_id'] as String,
        scheduleId: json['schedule_id'] as String,
        scheduledOn: DateTime.parse(json['scheduled_on'] as String),
        time: json['time_of_day'] as String,
        name: json['name'] as String,
        strengthValue: double.parse(json['strength_value'] as String),
        strengthUnit: StrengthUnit.fromApi(json['strength_unit'] as String),
        dosageForm: DosageForm.values.byName(json['dosage_form'] as String),
        doseValue: double.parse(json['dose_value'] as String),
        doseUnit: unit,
        missedAfterMinutes: json['missed_after_minutes'] as int? ?? 60,
        instructions: json['instructions'] as String?,
        reason: json['reason_for_use'] as String?,
        timingState: json['timing_state'] == null
            ? null
            : DoseTimingState.values.byName(json['timing_state'] as String),
        record: recordJson == null
            ? null
            : DoseRecordModel.fromJson(recordJson).toEntity(),
        snooze: SharedSnooze.fromJson(json['snooze']),
      ),
    );
  }

  DoseOccurrence toEntity() => _entity;
}

/// Maps dose record data between the API and app.
class DoseRecordModel {
  const DoseRecordModel(this._entity);

  final DoseRecord _entity;

  factory DoseRecordModel.fromJson(Map<String, dynamic> json) {
    final takenAt = json['taken_at'] as String?;
    final recordedBy = json['recorded_by'] as Map<String, dynamic>?;
    return DoseRecordModel(
      DoseRecord(
        id: json['id'] as String,
        outcome: DoseOutcome.values.byName(json['outcome'] as String),
        takenAt: takenAt == null ? null : DateTime.parse(takenAt).toLocal(),
        skipReasonCode: json['skip_reason_code'] as String?,
        skipReasonNote: json['skip_reason_note'] as String?,
        recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
        recordedByAccountId: recordedBy?['account_id'] as String?,
        recordedByName: recordedBy?['name'] as String?,
        recordedByAvatarCode: recordedBy?['avatar_code'] as String?,
      ),
    );
  }

  DoseRecord toEntity() => _entity;
}
