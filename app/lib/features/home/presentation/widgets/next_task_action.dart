import 'dart:async';

import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/task_viewer_scope.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_attend_button.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What «المهمة القادمة» answers on the card itself: a reading that can be
/// recorded already, or «حضرت» from an hour before a visit ([attendEarly])
/// for those who go with it, as the visit's row in «اليوم» does.
class NextTaskAction extends StatelessWidget {
  const NextTaskAction({
    super.key,
    required this.task,
    required this.circleId,
    required this.now,
  });

  final NextTask task;
  final String circleId;
  final DateTime now;

  static const EdgeInsets _gap = EdgeInsets.only(top: AppSpacing.sm);

  @override
  Widget build(BuildContext context) {
    final Widget? action = _action(context);
    if (action == null) return const SizedBox.shrink();
    return Padding(padding: _gap, child: action);
  }

  Widget? _action(BuildContext context) {
    final MeasurementOccurrence? measurement = task.measurement;
    if (measurement != null &&
        DateUtils.isSameDay(task.at, now) &&
        canRecordOccurrence(
          resolved:
              measurement.status != MeasurementStatus.upcoming &&
              measurement.status != MeasurementStatus.due &&
              measurement.status != MeasurementStatus.missed,
          scheduledAt: wallClockAt(measurement.scheduledOn, measurement.time),
          now: now,
        )) {
      // The tasks read again by themselves when the answer is saved.
      return FilledButton(
        onPressed: () => unawaited(
          showMeasurementReadingSheet(context, occurrence: measurement),
        ),
        child: Text(context.tr('measurements.record_reading')),
      );
    }
    final appointment = task.appointment;
    // Asked only of those who go: the patient and the visit's companions.
    if (appointment != null &&
        appointment.canAttendAt(now, scheduleDay(now)) &&
        (TaskViewerScope.of(context)?.goesWith(appointment.companionIds) ??
            false)) {
      return AppointmentAttendButton(value: appointment, circleId: circleId);
    }
    return null;
  }
}
