import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_details.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:flutter/material.dart';

/// What the next card says under its picture: when, the time, the name and
/// what to take.
class SimplifiedNextText extends StatelessWidget {
  const SimplifiedNextText({
    super.key,
    required this.task,
    required this.day,
    required this.when,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «التالي، بعد ساعتين», or what the task was put off to.
  final String when;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SimplifiedStyle.pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SimplifiedSnoozedLine(
            text: when,
            task: task,
            day: day,
            style: SimplifiedStyle.label(
              SimplifiedStyle.caption,
              color: task.status == TodayTaskStatus.late
                  ? SimplifiedColors.attentionInk
                  : SimplifiedColors.muted,
            ),
          ),
          Text(
            simplifiedTime(context, task.time),
            style: SimplifiedStyle.head(SimplifiedStyle.time, height: 1.1),
          ),
          const Divider(height: 28, color: SimplifiedColors.line),
          Text(
            simplifiedTaskTitle(context, task),
            style: SimplifiedStyle.head(SimplifiedStyle.name),
          ),
          SimplifiedTaskDetails(task: task, day: day),
        ],
      ),
    );
  }
}

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
