import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_version.dart';

/// One dose in «سجل الجرعات»: a dose of a dose time, or one more of
/// «سجّل جرعة الآن». [day] is the patient's day it sits under, [at] its
/// wall-clock moment for the order, and [recorder] who recorded it, for
/// the filter.
sealed class DoseHistoryEntry {
  const DoseHistoryEntry();

  DateTime get day;
  DateTime get at;
  (String?, String?) get recorder;
}

final class ScheduledDoseEntry extends DoseHistoryEntry {
  const ScheduledDoseEntry(this.occurrence);

  final DoseOccurrence occurrence;

  @override
  DateTime get day => occurrence.scheduledOn;

  @override
  DateTime get at {
    final List<String> parts = occurrence.time.split(':');
    final DateTime on = occurrence.scheduledOn;
    return DateTime.utc(
      on.year,
      on.month,
      on.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  (String?, String?) get recorder => (
    occurrence.record?.recordedByAccountId,
    occurrence.record?.recordedByName,
  );
}

/// An extra dose, with the medicine it was of as its page shows it.
final class ExtraDoseEntry extends DoseHistoryEntry {
  const ExtraDoseEntry(this.dose, this.medicine, {required this.at});

  final ExtraDose dose;
  final MedicationVersion medicine;

  /// When it was taken, on the patient's wall clock.
  @override
  final DateTime at;

  @override
  DateTime get day => DateTime(at.year, at.month, at.day);

  @override
  (String?, String?) get recorder =>
      (dose.recordedByAccountId, dose.recordedByName);
}

/// [doses] and [extras] of [medicine] in one history, newest first. Only
/// the extras from [from] on: the days before are not read yet («أقدم»).
List<DoseHistoryEntry> doseHistoryEntries(
  PatientClock clock, {
  required Iterable<DoseOccurrence> doses,
  required Iterable<ExtraDose> extras,
  required MedicationVersion medicine,
  DateTime? from,
}) {
  final List<DoseHistoryEntry> entries = <DoseHistoryEntry>[
    for (final DoseOccurrence dose in doses) ScheduledDoseEntry(dose),
    for (final ExtraDose dose in extras)
      ExtraDoseEntry(dose, medicine, at: clock.wallTime(dose.takenAt)),
  ];
  return <DoseHistoryEntry>[
    for (final DoseHistoryEntry entry in entries)
      if (from == null || !entry.day.isBefore(from)) entry,
  ]..sort((DoseHistoryEntry a, DoseHistoryEntry b) => b.at.compareTo(a.at));
}
