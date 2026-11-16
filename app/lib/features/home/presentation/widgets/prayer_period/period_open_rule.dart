import 'package:app/core/services/tap_focus.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entries.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entry.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entry_key.dart';

/// Whether a prayer period opens by itself: the patient is in it, or the
/// notification just tapped is about one of its rows ([TapFocus]).
///
/// Attention, a missed reading and a visit opened their periods too, so
/// most of the day stood open and «اليوم» read as one long list. They
/// are still counted on the closed period's own line.
bool periodStartsOpen(
  PeriodEntries entries, {
  required bool current,
  required String circleId,
}) =>
    current ||
    entries.sorted.any(
      (PeriodEntry row) =>
          periodEntryKey(row, circleId) == TapFocus.instance.key,
    );
