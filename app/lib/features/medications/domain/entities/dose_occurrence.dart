import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:equatable/equatable.dart';

enum DoseOutcome { taken, skipped }

enum DoseTimingState { upcoming, due, late, missed }

enum DoseSkipReason {
  forgotten,
  unavailable,
  sideEffects,
  patientRefused,
  other;

  String get apiValue => switch (this) {
    sideEffects => 'side_effects',
    patientRefused => 'patient_refused',
    _ => name,
  };
}

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
    required this.strengthValue,
    required this.strengthUnit,
    required this.dosageForm,
    required this.doseValue,
    required this.doseUnit,
    this.timingState,
    this.instructions,
    this.record,
  });

  final String planId;
  final String scheduleId;
  final DateTime scheduledOn;
  final String time;
  final String name;
  final double strengthValue;
  final StrengthUnit strengthUnit;
  final DosageForm dosageForm;
  final double doseValue;
  final DoseUnit doseUnit;
  final String? instructions;
  final DoseRecord? record;
  final DoseTimingState? timingState;

  DoseOccurrence withRecord(DoseRecord value) => DoseOccurrence(
    planId: planId,
    scheduleId: scheduleId,
    scheduledOn: scheduledOn,
    time: time,
    name: name,
    strengthValue: strengthValue,
    strengthUnit: strengthUnit,
    dosageForm: dosageForm,
    doseValue: doseValue,
    doseUnit: doseUnit,
    instructions: instructions,
    record: value,
    timingState: null,
  );

  @override
  List<Object?> get props => [
    planId,
    scheduleId,
    scheduledOn,
    time,
    name,
    strengthValue,
    strengthUnit,
    dosageForm,
    doseValue,
    doseUnit,
    instructions,
    record,
    timingState,
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
