import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_today_row.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_row.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_row.dart';
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
    final List<(String, Widget)> rows = <(String, Widget)>[
      for (final DoseOccurrence dose in doses)
        (
          dose.time,
          TodayDoseRow(
            occurrence: dose,
            circleId: circleId,
            canManage: canManage,
            now: now,
          ),
        ),
      for (final MeasurementOccurrence task in measurements)
        (
          task.time,
          MeasurementTaskRow(task: task, now: now, circleId: circleId),
        ),
      for (final CareAppointment visit in appointments)
        (
          visit.time,
          AppointmentTodayRow(
            value: visit,
            circleId: circleId,
            canManage: canManage,
          ),
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (String, Widget) row in rows) ...<Widget>[
          row.$2,
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
