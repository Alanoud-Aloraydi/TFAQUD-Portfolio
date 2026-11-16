import 'package:app/features/medications/domain/entities/dose_unit.dart';
import 'package:app/features/medications/domain/entities/schedule_repeat.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/medications/domain/entities/dosage_form.dart';
export 'package:app/features/medications/domain/entities/dosage_form_unit.dart';
export 'package:app/features/medications/domain/entities/dose_unit.dart';
export 'package:app/features/medications/domain/entities/dose_unit_value.dart';
export 'package:app/features/medications/domain/entities/medication_schedule_draft.dart';
export 'package:app/features/medications/domain/entities/schedule_repeat.dart';
export 'package:app/features/medications/domain/entities/strength_unit.dart';

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
