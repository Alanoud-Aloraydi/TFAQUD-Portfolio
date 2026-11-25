import 'package:app/core/localization/appointment_texts.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/home/presentation/widgets/next_task_header.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the next task is and when: its kind and name, the day and time, the
/// time left when it is within two days, and who goes with a visit.
class NextTaskSummary extends StatelessWidget {
  const NextTaskSummary({
    super.key,
    required this.task,
    required this.circleId,
    required this.now,
  });

  final NextTask task;
  final String circleId;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final measurement = task.measurement;
    final appointment = task.appointment;
    final minutes = (task.at.difference(now).inSeconds + 59) ~/ 60;
    final relative = afterDuration(context, minutes);
    final time =
        task.medication?.time ?? measurement?.time ?? appointment!.time;
    // What the task is reads as one sentence; the answer below stays
    // a button of its own.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NextTaskHeader(task: task, circleId: circleId),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${context.tr('common.weekdays.${task.at.weekday}')} '
            '${formatMedicationDate(context, task.at)}، '
            '${clockText(time)}',
            semanticsLabel: spoken(
              '${context.tr('common.weekdays.${task.at.weekday}')} '
              '${formatMedicationDate(context, task.at)}، '
              '${clockText(time)}',
            ),
          ),
          if (minutes < 2880)
            Text(relative, style: Theme.of(context).textTheme.titleMedium),
          if (appointment != null)
            Text(appointmentCompanionLine(context, appointment)),
        ],
      ),
    );
  }
}

/// The name of [task]: the medicine's, the measurement's kind, or the
/// visit's title.
String nextTaskTitle(BuildContext context, NextTask task) {
  final measurement = task.measurement;
  return task.medication?.name ??
      (measurement == null
          ? appointmentTitle(context, task.appointment!)
          : context.tr(
              measurement.kind == MeasurementKind.bp
                  ? 'measurements.bp'
                  : 'measurements.glucose',
            ));
}

/// How the card of [task] shows its kind: the words over the name, the
/// icon, and the color of the circle behind the icon.
(String headerKey, IconData icon, Color iconBackground) nextTaskLook(
  NextTask task,
) => task.medication != null
    ? (
        'today_dashboard.next_medication',
        CareVisuals.medicationIcon,
        CareVisuals.medicationTile,
      )
    : task.measurement != null
    ? (
        'today_dashboard.next_measurement',
        CareVisuals.measurementIcon,
        CareVisuals.measurementTile,
      )
    : (
        'today_dashboard.next_appointment',
        appointmentKindIcon(task.appointment!.kind),
        CareVisuals.appointmentTile,
      );
