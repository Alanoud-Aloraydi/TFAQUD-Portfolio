import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/material.dart';

/// Put off by someone in the circle (the server's), while it waits; on
/// the patient's wall clock, as the rest of the card. Null once that
/// moment has passed, or when nobody put the dose off.
SharedSnooze? doseSnoozeWaiting(
  BuildContext context,
  DoseOccurrence occurrence,
) {
  final PatientClock clock = PatientClockScope.of(context);
  final SharedSnooze? shared = occurrence.snooze;
  return shared != null && clock.wallTime(shared.remindAt).isAfter(clock.now())
      ? shared
      : null;
}
