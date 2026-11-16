import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/widgets.dart';

/// The circle's own snooze on [occurrence] while it still waits (the
/// server's), on the patient's wall clock, as the rest of the card. Null
/// once the time it was put off to has passed.
SharedSnooze? waitingSnooze(BuildContext context, DoseOccurrence occurrence) {
  final PatientClock clock = PatientClockScope.of(context);
  final SharedSnooze? shared = occurrence.snooze;
  if (shared == null) return null;
  return clock.wallTime(shared.remindAt).isAfter(clock.now()) ? shared : null;
}
