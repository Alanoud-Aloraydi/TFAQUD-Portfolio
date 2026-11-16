import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/features/medications/domain/entities/dose_record.dart';
import 'package:app/features/medications/domain/entities/dose_timing_state.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/medications/domain/entities/dose_lateness.dart';
export 'package:app/features/medications/domain/entities/dose_occurrence_copies.dart';
export 'package:app/features/medications/domain/entities/dose_outcome.dart';
export 'package:app/features/medications/domain/entities/dose_record.dart';
export 'package:app/features/medications/domain/entities/dose_record_draft.dart';
export 'package:app/features/medications/domain/entities/dose_skip_reason.dart';
export 'package:app/features/medications/domain/entities/dose_timing_state.dart';

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
