import 'package:app/app/services/reminders/shared_snooze.dart';
import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/medications/domain/entities/dose_record.dart';
export 'package:app/features/medications/domain/entities/dose_record_draft.dart';

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

  /// Whether it belongs in «سجل الجرعات» at [now] (the patient's wall
  /// time): recorded, or its time came. One still ahead is not history.
  bool isHistoryAt(DateTime now) =>
      record != null || !wallClockAt(scheduledOn, time).isAfter(now);

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

/// Where an unrecorded dose stands against its time: not yet, due (its
/// first 15 minutes), late (until `DoseOccurrence.missedAfterMinutes`) or
/// missed. The server sends it; `medicationTimingState` recomputes it as
/// the minutes pass on screen.
enum DoseTimingState { upcoming, due, late, missed }

/// What was recorded for a dose: taken, or not taken («تخطي»). The API's
/// words are the names.
enum DoseOutcome { taken, skipped }

/// Adds dose unit value helpers to its target type.
extension DoseUnitValue on DoseUnit {
  String get apiValue => this == DoseUnit.milliliter ? 'mL' : name;
}

enum DoseUnit { tablet, capsule, milliliter, drop, puff, unit }
