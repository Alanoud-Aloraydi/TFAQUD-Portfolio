import 'package:app/features/home/presentation/widgets/prayer_period/period_entries.dart';
import 'package:app/features/medications/presentation/today_medication_view.dart';

/// Whether a prayer period opens by itself: the patient is in it, or
/// something in it needs attention, or it has a visit.
bool periodStartsOpen(
  PeriodEntries entries,
  DateTime now, {
  required bool current,
}) =>
    current ||
    MedicationPeriodSummary(entries.doses, now).attentionCount > 0 ||
    entries.missedMeasurements > 0 ||
    entries.visits.isNotEmpty;
