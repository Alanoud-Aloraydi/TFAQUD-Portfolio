import 'package:app/core/constants/plan_limits.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:equatable/equatable.dart';

/// Preserves one effective version of a medication plan.
class MedicationVersion extends Equatable {
  MedicationVersion({
    required this.number,
    required this.name,
    required this.strengthValue,
    required this.strengthUnit,
    required this.dosageForm,
    required this.startsOn,
    required List<MedicationSchedule> schedules,
    this.missedAfterMinutes = PlanLimits.defaultMissedAfterMinutes,
    this.reason,
    this.instructions,
    this.endsOn,
    this.effectiveUntilOn,
    required this.effectiveFromOn,
  }) : schedules = List.unmodifiable(schedules);

  final int number;
  final String name;
  final double strengthValue;
  final StrengthUnit strengthUnit;
  final DosageForm dosageForm;
  final String? reason;
  final String? instructions;
  final DateTime startsOn;
  final DateTime? endsOn;
  final DateTime effectiveFromOn;
  final DateTime? effectiveUntilOn;
  final List<MedicationSchedule> schedules;
  final int missedAfterMinutes;

  @override
  List<Object?> get props => [
    number,
    name,
    strengthValue,
    strengthUnit,
    dosageForm,
    reason,
    instructions,
    startsOn,
    endsOn,
    effectiveFromOn,
    effectiveUntilOn,
    schedules,
    missedAfterMinutes,
  ];
}
