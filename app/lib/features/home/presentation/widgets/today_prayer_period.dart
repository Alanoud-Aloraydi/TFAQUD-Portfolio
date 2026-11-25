import 'package:app/app/services/tap_focus.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/home/presentation/widgets/period_entries.dart';
import 'package:app/features/home/presentation/widgets/period_task_rows.dart';
import 'package:app/features/home/presentation/widgets/prayer_period_view.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:flutter/material.dart';

/// One prayer period of «اليوم»: its name and time, and the doses, readings
/// and visits nearest to it. When it opens by itself: period_open_rule.dart.
class TodayPrayerPeriod extends StatelessWidget {
  const TodayPrayerPeriod({
    super.key,
    required this.prayer,
    required this.time,
    required this.nextTime,
    required this.prayerTimes,
    required this.occurrences,
    required this.measurementTasks,
    required this.appointments,
    required this.circleId,
    required this.canManage,
    required this.now,
  });
  final Prayer prayer;
  final String time;
  final String? nextTime;
  final Map<Prayer, String> prayerTimes;
  final List<DoseOccurrence> occurrences;
  final List<MeasurementOccurrence> measurementTasks;
  final List<CareAppointment> appointments;
  final String circleId;
  final bool canManage;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final PeriodEntries entries = PeriodEntries(
      prayer,
      prayerTimes,
      occurrences: occurrences,
      measurementTasks: measurementTasks,
      appointments: appointments,
    );
    final bool current = isInPeriod(now, time, nextTime);
    return PrayerPeriodView(
      prayer: prayer,
      time: time,
      current: current,
      open: periodStartsOpen(entries, current: current, circleId: circleId),
      rows: entries.sorted,
      circleId: circleId,
      canManage: canManage,
      now: now,
    );
  }
}

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
