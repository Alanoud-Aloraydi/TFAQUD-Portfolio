import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:equatable/equatable.dart';

class MedicationVersion extends Equatable {
  MedicationVersion({
    required this.number,
    required this.name,
    required this.dosageForm,
    required this.startsOn,
    required List<MedicationSchedule> schedules,
    this.strength,
    this.reason,
    this.instructions,
    this.endsOn,
  }) : schedules = List.unmodifiable(schedules);

  final int number;
  final String name;
  final String? strength;
  final DosageForm dosageForm;
  final String? reason;
  final String? instructions;
  final DateTime startsOn;
  final DateTime? endsOn;
  final List<MedicationSchedule> schedules;

  @override
  List<Object?> get props => [
    number,
    name,
    strength,
    dosageForm,
    reason,
    instructions,
    startsOn,
    endsOn,
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

  @override
  List<Object?> get props => [id, createdAt, discontinuedAt, version];
}

class MedicationPlanDraft extends Equatable {
  MedicationPlanDraft({
    required this.name,
    required this.dosageForm,
    required this.startsOn,
    required List<MedicationScheduleDraft> schedules,
    this.strength,
    this.reason,
    this.instructions,
    this.endsOn,
  }) : schedules = List.unmodifiable(schedules);

  final String name;
  final String? strength;
  final DosageForm dosageForm;
  final String? reason;
  final String? instructions;
  final DateTime startsOn;
  final DateTime? endsOn;
  final List<MedicationScheduleDraft> schedules;

  Map<String, Object?> toJson({int? expectedVersion}) => {
    'name': name,
    'strength_text': strength,
    'dosage_form': dosageForm.name,
    'reason_for_use': reason,
    'instructions': instructions,
    'treatment_starts_on': _date(startsOn),
    'treatment_ends_on': endsOn == null ? null : _date(endsOn!),
    'schedules': schedules.map((item) => item.toJson()).toList(),
    'expected_version_number': ?expectedVersion,
  };

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
    name,
    strength,
    dosageForm,
    reason,
    instructions,
    startsOn,
    endsOn,
    schedules,
  ];
}
