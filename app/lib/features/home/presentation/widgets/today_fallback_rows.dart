import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entry.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_task_rows.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/material.dart';

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
          hasPhoto: false,
          now: now,
        ),
        if (entries.isNotEmpty) const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
