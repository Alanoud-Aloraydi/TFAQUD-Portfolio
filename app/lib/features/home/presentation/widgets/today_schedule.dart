import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/tap_focus.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/home/presentation/widgets/period_task_rows.dart';
import 'package:app/features/home/presentation/widgets/prayer_period_view.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The day's rows under each prayer period, or in time order while the
/// prayer times are not available ([day] null).
class TodaySchedule extends StatelessWidget {
  const TodaySchedule({
    super.key,
    required this.snapshot,
    required this.day,
    required this.circleId,
    required this.canManage,
  });

  final TodaySnapshot snapshot;
  final PrayerDay? day;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final PrayerDay? day = this.day;
    if (day == null) {
      return TodayFallbackRows(
        doses: snapshot.medications.todayOccurrences,
        measurements: snapshot.todayMeasurements,
        appointments: snapshot.todayAppointments,
        circleId: circleId,
        canManage: canManage,
        now: snapshot.now,
      );
    }
    return TodayPrayerPeriods(
      snapshot: snapshot,
      day: day,
      circleId: circleId,
      canManage: canManage,
    );
  }
}

/// Today's schedule when the prayer times are not available: the same rows
/// as under a prayer period, in time order, with the same gap between them.
class TodayFallbackRows extends StatelessWidget {
  const TodayFallbackRows({
    super.key,
    required this.doses,
    required this.measurements,
    required this.appointments,
    required this.circleId,
    required this.canManage,
    required this.now,
  });

  final List<DoseOccurrence> doses;
  final List<MeasurementOccurrence> measurements;
  final List<CareAppointment> appointments;
  final String circleId;
  final bool canManage;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final List<PeriodEntry> entries = <PeriodEntry>[
      for (final DoseOccurrence dose in doses) PeriodEntry.dose(dose),
      for (final MeasurementOccurrence task in measurements)
        PeriodEntry.measurement(task),
      for (final CareAppointment visit in appointments)
        PeriodEntry.visit(visit),
    ]..sort((PeriodEntry a, PeriodEntry b) => a.time.compareTo(b.time));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ...periodTaskRows(
          entries,
          circleId: circleId,
          canManage: canManage,
          now: now,
        ),
        if (entries.isNotEmpty) const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// The patient's city and the day's rows under each prayer period.
class TodayPrayerPeriods extends StatelessWidget {
  const TodayPrayerPeriods({
    super.key,
    required this.snapshot,
    required this.day,
    required this.circleId,
    required this.canManage,
  });

  final TodaySnapshot snapshot;
  final PrayerDay day;
  final String circleId;
  final bool canManage;

  // A tapped notification opens the period its item is in.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: TapFocus.instance,
    builder: (BuildContext context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InsetText(
          context.tr('prayer_times.city', args: <String>[day.city]),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < Prayer.values.length; index++) ...<Widget>[
          _period(index, day),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    ),
  );

  Widget _period(int index, PrayerDay day) => TodayPrayerPeriod(
    prayer: Prayer.values[index],
    time: day.times[Prayer.values[index]]!,
    nextTime: index + 1 < Prayer.values.length
        ? day.times[Prayer.values[index + 1]]
        : null,
    prayerTimes: day.times,
    occurrences: snapshot.medications.todayOccurrences,
    measurementTasks: snapshot.todayMeasurements,
    appointments: snapshot.todayAppointments,
    circleId: circleId,
    canManage: canManage,
    now: snapshot.now,
  );
}

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

/// The doses, readings and visits whose nearest prayer is [prayer].
class PeriodEntries {
  PeriodEntries(
    Prayer prayer,
    Map<Prayer, String> prayerTimes, {
    required List<DoseOccurrence> occurrences,
    required List<MeasurementOccurrence> measurementTasks,
    required List<CareAppointment> appointments,
  }) {
    List<T> mine<T>(List<T> all, String Function(T) timeOf) => all
        .where((item) => nearestPrayer(timeOf(item), prayerTimes) == prayer)
        .toList();
    doses = mine(occurrences, (item) => item.time);
    measurements = mine(measurementTasks, (item) => item.time);
    visits = mine(appointments, (item) => item.time);
  }

  late final List<DoseOccurrence> doses;
  late final List<MeasurementOccurrence> measurements;
  late final List<CareAppointment> visits;

  /// All tasks of the period, earliest first.
  List<PeriodEntry> get sorted => <PeriodEntry>[
    for (final item in doses) PeriodEntry.dose(item),
    for (final item in measurements) PeriodEntry.measurement(item),
    for (final item in visits) PeriodEntry.visit(item),
  ]..sort((first, second) => first.time.compareTo(second.time));
}
