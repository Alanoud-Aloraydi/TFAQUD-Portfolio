import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/home/presentation/widgets/period_task_rows.dart';
import 'package:app/features/home/presentation/widgets/today_prayer_periods.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
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
