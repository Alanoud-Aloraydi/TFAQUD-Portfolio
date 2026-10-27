import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:equatable/equatable.dart';

enum DoseOutcome { taken, skipped }

class DoseRecord extends Equatable {
  const DoseRecord({
    required this.id,
    required this.outcome,
    required this.recordedAt,
    this.takenAt,
    this.skipReasonCode,
    this.skipReasonNote,
  });

  final String id;
  final DoseOutcome outcome;
  final DateTime? takenAt;
  final String? skipReasonCode;
  final String? skipReasonNote;
  final DateTime recordedAt;

  @override
  List<Object?> get props => [
    id,
    outcome,
    takenAt,
    skipReasonCode,
    skipReasonNote,
    recordedAt,
  ];
}

class DoseOccurrence extends Equatable {
  const DoseOccurrence({
    required this.planId,
    required this.scheduleId,
    required this.scheduledOn,
    required this.time,
    required this.name,
    required this.dosageForm,
    required this.doseValue,
    required this.doseUnit,
    this.strength,
    this.instructions,
    this.record,
  });

  final String planId;
  final String scheduleId;
  final DateTime scheduledOn;
  final String time;
  final String name;
  final String? strength;
  final DosageForm dosageForm;
  final double doseValue;
  final DoseUnit doseUnit;
  final String? instructions;
  final DoseRecord? record;

  DoseOccurrence withRecord(DoseRecord value) => DoseOccurrence(
    planId: planId,
    scheduleId: scheduleId,
    scheduledOn: scheduledOn,
    time: time,
    name: name,
    strength: strength,
    dosageForm: dosageForm,
    doseValue: doseValue,
    doseUnit: doseUnit,
    instructions: instructions,
    record: value,
  );

  @override
  List<Object?> get props => [
    planId,
    scheduleId,
    scheduledOn,
    time,
    name,
    strength,
    dosageForm,
    doseValue,
    doseUnit,
    instructions,
    record,
  ];
}

class DoseRecordDraft extends Equatable {
  const DoseRecordDraft({
    required this.outcome,
    this.takenAt,
    this.skipReasonCode,
    this.skipReasonNote,
  });

  final DoseOutcome outcome;
  final DateTime? takenAt;
  final String? skipReasonCode;
  final String? skipReasonNote;

  Map<String, Object?> toJson() => {
    'outcome': outcome.name,
    'taken_at': takenAt?.toUtc().toIso8601String(),
    'skip_reason_code': skipReasonCode,
    'skip_reason_note': skipReasonNote,
  };

  @override
  List<Object?> get props => [outcome, takenAt, skipReasonCode, skipReasonNote];
}
