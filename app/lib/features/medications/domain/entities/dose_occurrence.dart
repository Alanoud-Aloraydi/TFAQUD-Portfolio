import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:equatable/equatable.dart';

/// What was recorded for a dose: taken, or not taken («تخطي»). The API's
/// words are the names.
enum DoseOutcome { taken, skipped }

/// Where an unrecorded dose stands against its time: not yet, due (its
/// first 15 minutes), late (until [DoseOccurrence.missedAfterMinutes]) or
/// missed. The server sends it; [medicationTimingState] recomputes it as
/// the minutes pass on screen.
enum DoseTimingState { upcoming, due, late, missed }

/// Why a dose was not taken, as offered on the skip sheet.
enum DoseSkipReason {
  forgotten,
  unavailable,
  sideEffects,
  patientRefused,
  other;

  /// The API's word for the reason.
  String get apiValue => switch (this) {
    sideEffects => 'side_effects',
    patientRefused => 'patient_refused',
    _ => name,
  };
}

/// The server's record of one dose explicitly taken or skipped; a dose
/// with no record has not been answered yet.
class DoseRecord extends Equatable {
  const DoseRecord({
    required this.id,
    required this.outcome,
    required this.recordedAt,
    this.takenAt,
    this.skipReasonCode,
    this.skipReasonNote,
    this.recordedByAccountId,
    this.recordedByName,
    this.recordedByAvatarCode,
  });

  final String id;
  final DoseOutcome outcome;

  /// The real moment it was taken; null when skipped.
  final DateTime? takenAt;
  final String? skipReasonCode;
  final String? skipReasonNote;

  /// When the server saved it.
  final DateTime recordedAt;

  /// Who recorded it: null for a dose from before this was tracked.
  final String? recordedByAccountId;
  final String? recordedByName;
  final String? recordedByAvatarCode;

  @override
  List<Object?> get props => [
    id,
    outcome,
    takenAt,
    skipReasonCode,
    skipReasonNote,
    recordedAt,
    recordedByAccountId,
    recordedByName,
    recordedByAvatarCode,
  ];
}

/// One expected dose the server computed from a plan's schedule: the
/// schedule ([scheduleId]) on the patient's day [scheduledOn] at the wall
/// time [time] («08:00» where the patient lives), with the medicine as it
/// was on that day and its [record] once answered. The pair
/// [scheduleId] + [scheduledOn] identifies it on the server.
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
    this.missedAfterMinutes = PlanLimits.defaultMissedAfterMinutes,
    this.timingState,
    this.instructions,
    this.reason,
    this.record,
    this.snooze,
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
  final int missedAfterMinutes;
  final String? instructions;

  /// What the medicine is for, as whoever added it wrote it («الضغط»).
  /// On the patient's own screen this says more than the strength does.
  final String? reason;
  final DoseRecord? record;
  final DoseTimingState? timingState;

  /// Who in the circle put it off, and until when; null when it is not
  /// put off (or once it is recorded).
  final SharedSnooze? snooze;

  /// Whether the dose was taken at or after its missed boundary,
  /// [missedAfterMinutes] after its time on the patient's [clock] (the
  /// «بعد الموعد» status). False when it was not taken.
  bool isTakenLate(PatientClock clock) {
    final DateTime? takenAt = record?.takenAt;
    if (record?.outcome != DoseOutcome.taken || takenAt == null) return false;
    final DateTime boundary = clock
        .momentOf(scheduledOn, time)
        .add(Duration(minutes: missedAfterMinutes));
    return !takenAt.toUtc().isBefore(boundary);
  }

  /// This dose answered with [value], as the server saved it.
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
    missedAfterMinutes: missedAfterMinutes,
    instructions: instructions,
    reason: reason,
    record: value,
    timingState: null,
  );

  /// This dose put off by [value], as the server keeps it.
  DoseOccurrence withSnooze(SharedSnooze? value) => DoseOccurrence(
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
    missedAfterMinutes: missedAfterMinutes,
    instructions: instructions,
    reason: reason,
    record: record,
    timingState: timingState,
    snooze: value,
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
    missedAfterMinutes,
    instructions,
    reason,
    record,
    timingState,
    snooze,
  ];
}

/// The answer to a dose before it is sent: taken at [takenAt] (a real
/// moment, sent in UTC), or skipped with an optional reason.
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

  /// The body of `PUT medication-dose-records/{schedule}/{day}`.
  Map<String, Object?> toJson() => {
    'outcome': outcome.name,
    'taken_at': takenAt?.toUtc().toIso8601String(),
    'skip_reason_code': skipReasonCode,
    'skip_reason_note': skipReasonNote,
  };

  @override
  List<Object?> get props => [outcome, takenAt, skipReasonCode, skipReasonNote];
}
