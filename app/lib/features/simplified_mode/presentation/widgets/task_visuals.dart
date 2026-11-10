import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// A medicine's photo, the way the patient recognises it; while it has
/// none, the medicines' own look ([CareVisuals]): a pill on green.
class MedicinePhoto extends StatelessWidget {
  const MedicinePhoto({
    super.key,
    required this.circleId,
    required this.planId,
    required this.height,
    this.width = double.infinity,
    this.radius = SimplifiedStyle.radius,
    this.iconSize = 44,
  });

  final String circleId;
  final String planId;
  final double height;
  final double width;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return PrivatePhoto(
      path: ApiEndpoints.medicationPhoto(circleId, planId),
      height: height,
      width: width,
      radius: radius,
      openViewer: false,
      fallback: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: CareVisuals.medicationTile,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(
          CareVisuals.medicationIcon,
          size: iconSize,
          color: AppSemanticColors.onSettingsTile,
        ),
      ),
    );
  }
}

/// The icon of a measurement kind, as the detailed mode's measurement rows
/// draw it: a drop for glucose, a heart for blood pressure.
IconData measurementIcon(MeasurementKind kind) =>
    kind == MeasurementKind.bp ? AppIcons.heart : AppIcons.drop;

/// The detailed mode's settings icon square (SettingsIconTile), in this
/// mode's size: a kind's icon on its colour ([CareVisuals]). Decorative:
/// the row's words say what it is.
class CareIconTile extends StatelessWidget {
  const CareIconTile({
    super.key,
    required this.icon,
    required this.background,
    this.size = 44,
  });

  final IconData icon;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          // A quarter of the side, as iOS Settings' squares.
          borderRadius: BorderRadius.circular(size / 4),
        ),
        child: Icon(
          icon,
          size: size / 2,
          color: AppSemanticColors.onSettingsTile,
        ),
      ),
    );
  }
}

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
