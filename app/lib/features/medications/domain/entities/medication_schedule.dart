import 'package:equatable/equatable.dart';

enum DosageForm { tablet, capsule, liquid, drops, inhaler, injection }

enum DoseUnit { tablet, capsule, milliliter, drop, puff, unit }

enum StrengthUnit {
  milligram('mg'),
  microgram('mcg'),
  milligramPerMilliliter('mg/mL'),
  milligramPerFiveMilliliters('mg/5mL'),
  microgramPerDose('mcg/dose'),
  unitPerMilliliter('unit/mL'),
  percent('%');

  const StrengthUnit(this.apiValue);

  final String apiValue;

  static StrengthUnit fromApi(String value) =>
      values.firstWhere((unit) => unit.apiValue == value);
}

extension DosageFormUnit on DosageForm {
  List<DoseUnit> get doseUnits => switch (this) {
    DosageForm.tablet => const [DoseUnit.tablet],
    DosageForm.capsule => const [DoseUnit.capsule],
    DosageForm.liquid => const [DoseUnit.milliliter],
    DosageForm.drops => const [DoseUnit.drop],
    DosageForm.inhaler => const [DoseUnit.puff],
    DosageForm.injection => const [DoseUnit.milliliter, DoseUnit.unit],
  };

  DoseUnit get defaultDoseUnit => doseUnits.first;
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
