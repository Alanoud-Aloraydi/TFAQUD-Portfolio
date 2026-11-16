import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/care_icon_tile.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_icon.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:flutter/material.dart';

/// A task's small picture on a row: the medicine's photo, or the
/// measurement's or the appointment's icon square.
class TaskThumb extends StatelessWidget {
  const TaskThumb({
    super.key,
    required this.task,
    required this.circleId,
    this.size = 60,
  });

  final TodayTask task;
  final String circleId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (task.kind == TodayTaskKind.medication) {
      return MedicinePhoto(
        circleId: circleId,
        planId: task.dose!.planId,
        height: size,
        width: size,
        radius: 18,
        iconSize: size / 2,
      );
    }
    return task.kind == TodayTaskKind.measurement
        ? CareIconTile(
            icon: measurementIcon(task.measurement!.kind),
            background: CareVisuals.measurementTile,
            size: size,
          )
        : CareIconTile(
            icon: CareVisuals.appointmentIcon,
            background: CareVisuals.appointmentTile,
            size: size,
          );
  }
}
