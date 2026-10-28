import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:equatable/equatable.dart';

class MedicationVersion extends Equatable {
  MedicationVersion({
    required this.number,
    required this.name,
    required this.strengthValue,
    required this.strengthUnit,
    required this.dosageForm,
    required this.startsOn,
    required List<MedicationSchedule> schedules,
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
  ];
}

class MedicationPlan extends Equatable {
  const MedicationPlan({
    required this.id,
    required this.createdAt,
    required this.version,
    this.discontinuedAt,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? discontinuedAt;
  final MedicationVersion version;

  bool isPreviousOn(DateTime day) =>
      discontinuedAt != null ||
      (version.endsOn != null && version.endsOn!.isBefore(day));

  bool isScheduledOn(DateTime day) => version.effectiveFromOn.isAfter(day);

  @override
  List<Object?> get props => [id, createdAt, discontinuedAt, version];
}

class MedicationPlanDraft extends Equatable {
  MedicationPlanDraft({
    required this.name,
    required this.strengthValue,
    required this.strengthUnit,
    required this.dosageForm,
    required this.startsOn,
    required List<MedicationScheduleDraft> schedules,
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

  Map<String, Object?> toJson({int? expectedVersion}) => {
    'name': name,
    'strength_value': strengthValue,
    'strength_unit': strengthUnit.apiValue,
    'dosage_form': dosageForm.name,
    'reason_for_use': reason,
    'instructions': instructions,
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
  ];
}
