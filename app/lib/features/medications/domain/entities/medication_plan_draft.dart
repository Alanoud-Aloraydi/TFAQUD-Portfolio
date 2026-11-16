import 'package:app/core/constants/plan_limits.dart';
import 'package:app/features/medications/domain/entities/dosage_form.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/entities/strength_unit.dart';
import 'package:equatable/equatable.dart';

/// Holds editable medication plan values before saving.
class MedicationPlanDraft extends Equatable {
  MedicationPlanDraft({
    required this.name,
    required this.strengthValue,
    required this.strengthUnit,
    required this.dosageForm,
    required this.startsOn,
    required List<MedicationScheduleDraft> schedules,
    this.missedAfterMinutes = PlanLimits.defaultMissedAfterMinutes,
    this.reason,
    this.instructions,
    this.endsOn,
    this.effectiveFromOn,
  }) : schedules = List.unmodifiable(schedules);

  final String name;
  final double strengthValue;
  final StrengthUnit strengthUnit;
  final DosageForm dosageForm;
  final String? reason;
  final String? instructions;
  final DateTime startsOn;
  final DateTime? endsOn;
  final DateTime? effectiveFromOn;
  final List<MedicationScheduleDraft> schedules;
  final int missedAfterMinutes;

  Map<String, Object?> toJson({int? expectedVersion}) => {
    'name': name,
    'strength_value': strengthValue,
    'strength_unit': strengthUnit.apiValue,
    'dosage_form': dosageForm.name,
    'reason_for_use': reason,
    'instructions': instructions,
    'missed_after_minutes': missedAfterMinutes,
    'treatment_starts_on': _date(startsOn),
    'treatment_ends_on': endsOn == null ? null : _date(endsOn!),
    'schedules': schedules.map((item) => item.toJson()).toList(),
    'expected_version_number': ?expectedVersion,
    if (effectiveFromOn != null) 'effective_from_on': _date(effectiveFromOn!),
  };

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
    name,
    strengthValue,
    strengthUnit,
    dosageForm,
    reason,
    instructions,
    startsOn,
    endsOn,
    effectiveFromOn,
    schedules,
    missedAfterMinutes,
  ];
}
