import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';

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
        strength: json['strength_text'] as String?,
        dosageForm: DosageForm.values.byName(json['dosage_form'] as String),
        doseValue: double.parse(json['dose_value'] as String),
        doseUnit: unit,
        instructions: json['instructions'] as String?,
        record: recordJson == null
            ? null
            : DoseRecordModel.fromJson(recordJson).toEntity(),
      ),
    );
  }

  DoseOccurrence toEntity() => _entity;
}

class DoseRecordModel {
  const DoseRecordModel(this._entity);

  final DoseRecord _entity;

  factory DoseRecordModel.fromJson(Map<String, dynamic> json) {
    final takenAt = json['taken_at'] as String?;
    return DoseRecordModel(
      DoseRecord(
        id: json['id'] as String,
        outcome: DoseOutcome.values.byName(json['outcome'] as String),
        takenAt: takenAt == null ? null : DateTime.parse(takenAt).toLocal(),
        skipReasonCode: json['skip_reason_code'] as String?,
        skipReasonNote: json['skip_reason_note'] as String?,
        recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
      ),
    );
  }

  DoseRecord toEntity() => _entity;
}
