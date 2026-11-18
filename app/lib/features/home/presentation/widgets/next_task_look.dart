import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_icon.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
