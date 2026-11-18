import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_icon.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_icon.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_settings_tile_colors.dart';

/// The picture on top of the next card: the medicine's photo, or the tile
/// of a measurement or a visit.
class SimplifiedNextHero extends StatelessWidget {
  const SimplifiedNextHero({super.key, required this.task, required this.day});

  final TodayTask task;
  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    if (task.kind == TodayTaskKind.medication) {
      return MedicinePhoto(
        circleId: day.circleId,
        planId: task.dose!.planId,
        height: 210,
        radius: 0,
        iconSize: 96,
      );
    }
    final bool measurement = task.kind == TodayTaskKind.measurement;
    return Container(
      height: 150,
      width: double.infinity,
      color: measurement
          ? CareVisuals.measurementTile
          : CareVisuals.appointmentTile,
      child: Icon(
        measurement
            ? measurementIcon(task.measurement!.kind)
            : appointmentKindIcon(task.appointment!.kind),
        size: 80,
        color: AppSettingsTileColors.onTile,
      ),
    );
  }
}
