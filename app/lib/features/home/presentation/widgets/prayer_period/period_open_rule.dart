import 'package:app/core/services/tap_focus.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entries.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entry_key.dart';
import 'package:app/features/medications/presentation/today_medication_view.dart';

/// Whether a prayer period opens by itself: the patient is in it, or
/// something in it needs attention, or it has a visit, or the notification
/// just tapped is about one of its rows ([TapFocus]).
bool periodStartsOpen(
  PeriodEntries entries,
  DateTime now, {
  required bool current,
  required String circleId,
}) =>
    current ||
    MedicationPeriodSummary(entries.doses, now).attentionCount > 0 ||
    entries.missedMeasurements > 0 ||
    entries.visits.isNotEmpty ||
    entries.sorted.any(
      (PeriodEntry row) =>
          periodEntryKey(row, circleId) == TapFocus.instance.key,
    );
