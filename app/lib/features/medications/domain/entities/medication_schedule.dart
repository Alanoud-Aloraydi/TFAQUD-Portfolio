import 'package:equatable/equatable.dart';

enum DosageForm { tablet, capsule, liquid, drops, inhaler, injection }

enum DoseUnit { tablet, capsule, milliliter, drop, puff, unit }

extension DosageFormUnit on DosageForm {
  DoseUnit get doseUnit => switch (this) {
    DosageForm.tablet => DoseUnit.tablet,
    DosageForm.capsule => DoseUnit.capsule,
    DosageForm.liquid => DoseUnit.milliliter,
    DosageForm.drops => DoseUnit.drop,
    DosageForm.inhaler => DoseUnit.puff,
    DosageForm.injection => DoseUnit.unit,
  };
}

extension DoseUnitValue on DoseUnit {
  String get apiValue => this == DoseUnit.milliliter ? 'mL' : name;
}

class MedicationSchedule extends Equatable {
  MedicationSchedule({
    required this.id,
    required this.time,
    required this.doseValue,
    required this.doseUnit,
    required List<int> weekdays,
    this.instructions,
  }) : weekdays = List.unmodifiable(weekdays);

  final String id;
  final String time;
  final double doseValue;
  final DoseUnit doseUnit;
  final List<int> weekdays;
  final String? instructions;

  @override
  List<Object?> get props => [
    id,
    time,
    doseValue,
    doseUnit,
    weekdays,
    instructions,
  ];
}

class MedicationScheduleDraft extends Equatable {
  MedicationScheduleDraft({
    required this.time,
    required this.doseValue,
    required this.doseUnit,
    required List<int> weekdays,
    this.instructions,
  }) : weekdays = List.unmodifiable(weekdays);

  final String time;
  final double doseValue;
  final DoseUnit doseUnit;
  final List<int> weekdays;
  final String? instructions;

  Map<String, Object?> toJson() => {
    'time_of_day': time,
    'dose_value': doseValue,
    'dose_unit': doseUnit.apiValue,
    'weekdays': weekdays,
    'instructions': instructions,
  };

  @override
  List<Object?> get props => [
    time,
    doseValue,
    doseUnit,
    weekdays,
    instructions,
  ];
}
