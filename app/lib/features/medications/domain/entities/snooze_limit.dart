import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// The longest «ذكّرني لاحقًا» may put a dose off.
const Duration maxSnooze = Duration(hours: 12);

/// The choices of the snooze ruler are this many minutes apart.
const int snoozeStepMinutes = 5;

/// How long from [now] a dose due at [dose] may be put off: [maxSnooze] at
/// most, and never past halfway to [nextDose], the next dose of the same
/// medicine, so that the reminder never runs into it. In whole steps of
/// [snoozeStepMinutes]; zero when there is no room left.
Duration snoozeLimit({
  required DateTime now,
  required DateTime dose,
  DateTime? nextDose,
}) {
  Duration room = maxSnooze;
  if (nextDose != null && nextDose.isAfter(dose)) {
    final DateTime halfway = dose.add(nextDose.difference(dose) ~/ 2);
    final Duration untilHalfway = halfway.difference(now);
    if (untilHalfway < room) room = untilHalfway;
  }
  if (room.isNegative) return Duration.zero;
  final int steps = room.inMinutes ~/ snoozeStepMinutes;
  return Duration(minutes: steps * snoozeStepMinutes);
}

/// The moment of the next dose of [dose]'s medicine among [doses], on the
/// patient's [clock]; null when none is listed after it.
DateTime? nextDoseOf(
  DoseOccurrence dose,
  Iterable<DoseOccurrence> doses,
  PatientClock clock,
) {
  final DateTime at = clock.momentOf(dose.scheduledOn, dose.time);
  DateTime? next;
  for (final DoseOccurrence other in doses) {
    if (other.planId != dose.planId) continue;
    final DateTime moment = clock.momentOf(other.scheduledOn, other.time);
    if (!moment.isAfter(at)) continue;
    if (next == null || moment.isBefore(next)) next = moment;
  }
  return next;
}

/// [snoozeLimit] for [dose], from [now], with the next dose looked up in
/// [doses].
Duration doseSnoozeLimit(
  DoseOccurrence dose,
  Iterable<DoseOccurrence> doses,
  PatientClock clock,
  DateTime now,
) => snoozeLimit(
  now: now,
  dose: clock.momentOf(dose.scheduledOn, dose.time),
  nextDose: nextDoseOf(dose, doses, clock),
);
