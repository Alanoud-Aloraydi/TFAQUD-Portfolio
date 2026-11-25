import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';
import 'package:flutter/material.dart';

/// A new dose starts on the most common answer (one tablet at 8:00, every
/// day), so most people only check it.
ScheduleFormData newScheduleForm({DoseUnit doseUnit = DoseUnit.tablet}) =>
    ScheduleFormData(
      time: const TimeOfDay(hour: 8, minute: 0),
      dose: 1,
      doseUnit: doseUnit,
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );

/// A schedule already saved, as the form edits it.
ScheduleFormData scheduleFormOf(MedicationSchedule value) {
  final parts = value.time.split(':');
  // The form offers «كل كم يوم» in place of «شهري»: a monthly dose comes
  // in as every 30 days, and the editor says what it was.
  final bool monthly = value.repeat == ScheduleRepeat.monthly;
  return ScheduleFormData(
    time: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    dose: value.doseValue,
    doseUnit: value.doseUnit,
    repeat: monthly ? ScheduleRepeat.interval : value.repeat,
    // A dose switched to weekly starts on every day, as a new one.
    weekdays: value.weekdays.isEmpty
        ? <int>{1, 2, 3, 4, 5, 6, 7}
        : value.weekdays.toSet(),
    intervalDays: monthly
        ? ScheduleFormData.monthlyIntervalDays
        : value.intervalDays ?? ScheduleFormData.defaultIntervalDays,
    formerMonthDays: monthly ? value.monthDays : const <int>[],
    instructions: value.instructions,
  );
}
