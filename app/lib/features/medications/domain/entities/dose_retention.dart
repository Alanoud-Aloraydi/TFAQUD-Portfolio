import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';

/// Doses are kept three months: the server then deletes the records of a
/// day for good (backend app/medications/retention.py). The app warns
/// [warnDays] days before, so they can be exported first.
abstract final class DoseRetention {
  static const int keptDays = 90;
  static const int warnDays = 5;

  /// The first day whose doses are still kept on [today].
  static DateTime firstKeptDay(DateTime today) => addDays(today, -keptDays);

  /// The last day whose doses go within [warnDays] days: the days from
  /// [firstKeptDay] up to it. Null when the warning has nothing to say: no
  /// medicine was taken in those days, or the person exported or set the
  /// warning aside through [settled] (their days go with no new warning).
  static DateTime? goingThrough(
    DateTime today,
    Iterable<MedicationPlan> plans,
    DateTime? settled,
  ) {
    final DateTime last = addDays(firstKeptDay(today), warnDays - 1);
    final DateTime first = settled == null
        ? firstKeptDay(today)
        : _later(firstKeptDay(today), addDays(settled, 1));
    if (first.isAfter(last)) return null;
    final bool taken = plans.any(
      (MedicationPlan plan) =>
          !plan.version.startsOn.isAfter(last) &&
          !(_endOf(plan)?.isBefore(first) ?? false),
    );
    return taken ? last : null;
  }

  /// The medicine's last day: its end, or the day it was stopped.
  static DateTime? _endOf(MedicationPlan plan) {
    final DateTime? stopped = plan.discontinuedAt?.toLocal();
    final DateTime? stoppedOn = stopped == null
        ? null
        : DateTime(stopped.year, stopped.month, stopped.day);
    final DateTime? ends = plan.version.endsOn;
    if (ends == null || stoppedOn == null) return ends ?? stoppedOn;
    return ends.isBefore(stoppedOn) ? ends : stoppedOn;
  }

  /// What «لاحقًا» answers for: the days through [through], and the next
  /// ones, so the warning comes back in [warnDays] days, not every day.
  static DateTime laterThrough(DateTime through) =>
      addDays(through, warnDays - 1);

  static DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
}

/// Where an unrecorded dose stands at [now], the patient's wall time
/// ([PatientClock.now]); null once recorded.
DoseTimingState? medicationTimingState(DoseOccurrence item, DateTime now) {
  if (item.record != null) return null;
  final scheduled = wallClockAt(item.scheduledOn, item.time);
  if (now.isBefore(scheduled)) return DoseTimingState.upcoming;
  final minutes = now.difference(scheduled).inMinutes;
  if (minutes < 15) return DoseTimingState.due;
  if (minutes < item.missedAfterMinutes) return DoseTimingState.late;
  return DoseTimingState.missed;
}

/// Identifies an unresolved dose eligible for the next-task card.
bool medicationIsNextTaskCandidate(DoseOccurrence item, DateTime now) {
  final status = medicationTimingState(item, now);
  if (status == DoseTimingState.due || status == DoseTimingState.late) {
    return item.scheduledOn.year == now.year &&
        item.scheduledOn.month == now.month &&
        item.scheduledOn.day == now.day;
  }
  return status == DoseTimingState.upcoming;
}
