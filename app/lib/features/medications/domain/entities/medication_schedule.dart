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

/// Adds dosage form unit helpers to its target type.
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

/// Adds dose unit value helpers to its target type.
extension DoseUnitValue on DoseUnit {
  String get apiValue => this == DoseUnit.milliliter ? 'mL' : name;
}

/// How a dose time repeats: on chosen weekdays, every few days from the
/// treatment's start («نذكرك كل 3 أيام»), or on chosen days of the month.
/// The app offers the first two; a monthly schedule saved before stays
/// monthly until it is edited. The API's words are the names.
enum ScheduleRepeat { weekly, monthly, interval }

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

/// Holds editable medication schedule values before saving.
class MedicationScheduleDraft extends Equatable {
  MedicationScheduleDraft({
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

  final String time;
  final double doseValue;
  final DoseUnit doseUnit;
  final List<int> weekdays;
  final String? instructions;
  final ScheduleRepeat repeat;
  final List<int> monthDays;
  final int? intervalDays;

  /// A weekly schedule is sent as before (weekdays only), so it saves on a
  /// server without other repeats too; the others name their repeat.
  Map<String, Object?> toJson() => {
    'time_of_day': time,
    'dose_value': doseValue,
    'dose_unit': doseUnit.apiValue,
    ...switch (repeat) {
      ScheduleRepeat.weekly => <String, Object?>{'weekdays': weekdays},
      ScheduleRepeat.monthly => <String, Object?>{
        'repeat': repeat.name,
        'weekdays': const <int>[],
        'month_days': monthDays,
      },
      ScheduleRepeat.interval => <String, Object?>{
        'repeat': repeat.name,
        'weekdays': const <int>[],
        'interval_days': intervalDays,
      },
    },
    'instructions': instructions,
  };

  @override
  List<Object?> get props => [
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
