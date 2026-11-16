import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:flutter/widgets.dart';

/// How long [task] may be put off from [now]. A dose is never pushed past
/// halfway to the next dose of the same medicine, the same rule the
/// detailed mode's ruler follows; anything else has the plain limit.
Duration simplifiedSnoozeLimit(
  BuildContext context,
  TodayTask task,
  SimplifiedDay? day,
  DateTime now,
) {
  final DoseOccurrence? dose = task.dose;
  if (dose == null || day == null) return maxSnooze;
  final PatientClock clock = PatientClockScope.of(context);
  return doseSnoozeLimit(dose, day.doses, clock, now);
}
