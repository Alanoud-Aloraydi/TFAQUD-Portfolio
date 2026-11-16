import 'package:app/features/medications/domain/entities/dose_unit.dart';
import 'package:app/features/medications/domain/entities/dose_unit_value.dart';
import 'package:app/features/medications/domain/entities/schedule_repeat.dart';
import 'package:equatable/equatable.dart';

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
