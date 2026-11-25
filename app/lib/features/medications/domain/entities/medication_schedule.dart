import 'package:app/features/medications/domain/entities/dosage_form.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/schedule_repeat.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/medications/domain/entities/dosage_form.dart';
export 'package:app/features/medications/domain/entities/dose_occurrence.dart';
export 'package:app/features/medications/domain/entities/medication_schedule_draft.dart';
export 'package:app/features/medications/domain/entities/schedule_repeat.dart';

/// «نذكرك كل … يوم»: from every day to every 90 days, as the server allows.
const int maxIntervalDays = 90;

/// Defines when and how much medication is due.
class MedicationSchedule extends Equatable {
  MedicationSchedule({
    required this.id,
    required this.time,
    required this.doseValue,
    required this.doseUnit,
    required List<int> weekdays,
    this.instructions,
    this.repeat = ScheduleRepeat.weekly,
    List<int> monthDays = const <int>[],
    this.intervalDays,
  }) : weekdays = List.unmodifiable(weekdays),
       monthDays = List.unmodifiable(monthDays);

  final String id;
  final String time;
  final double doseValue;
  final DoseUnit doseUnit;

  /// ISO weekdays (1 Monday .. 7 Sunday) of a weekly schedule; empty for a
  /// monthly one.
  final List<int> weekdays;
  final String? instructions;
  final ScheduleRepeat repeat;

  /// Days of the month (1 .. 28, the days every month has, as the server
  /// allows) of a monthly schedule; empty for a weekly one.
  final List<int> monthDays;

  /// Every how many days an interval schedule repeats, counted from the
  /// treatment's start; null for the others.
  final int? intervalDays;

  @override
  List<Object?> get props => [
    id,
    time,
    doseValue,
    doseUnit,
    weekdays,
    instructions,
    repeat,
    monthDays,
    intervalDays,
  ];
}

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

/// Adds dosage form unit helpers to its target type.
extension DosageFormUnit on DosageForm {
  List<DoseUnit> get doseUnits => switch (this) {
    DosageForm.tablet => const [DoseUnit.tablet],
    DosageForm.capsule => const [DoseUnit.capsule],
    DosageForm.liquid => const [DoseUnit.milliliter],
    DosageForm.drops => const [DoseUnit.drop],
    DosageForm.inhaler => const [DoseUnit.puff],
    DosageForm.nebulizer => const [DoseUnit.milliliter],
    DosageForm.injection => const [DoseUnit.milliliter, DoseUnit.unit],
  };

  DoseUnit get defaultDoseUnit => doseUnits.first;
}
