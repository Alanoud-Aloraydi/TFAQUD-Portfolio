import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/care_icon_tile.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// A task's small picture with where it stands on its corner: ✓ done,
/// ● next, ! its time came, ○ later. Decorative: the row's words say it.
class SimplifiedTaskMark extends StatelessWidget {
  const SimplifiedTaskMark({
    super.key,
    required this.task,
    required this.circleId,
  });

  final TodayTask task;
  final String circleId;

  /// The colour of the status words beside the mark.
  static Color ink(TodayTaskStatus status) => switch (status) {
    TodayTaskStatus.done => SimplifiedColors.success,
    TodayTaskStatus.next => SimplifiedColors.ink,
    TodayTaskStatus.late => SimplifiedColors.attentionInk,
    TodayTaskStatus.later => SimplifiedColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final String glyph = switch (task.status) {
      TodayTaskStatus.done => '✓',
      TodayTaskStatus.next => '●',
      TodayTaskStatus.late => '!',
      TodayTaskStatus.later => '○',
    };
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        TaskThumb(task: task, circleId: circleId),
        PositionedDirectional(
          bottom: -4,
          start: -4,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: task.status == TodayTaskStatus.later
                  ? SimplifiedColors.control
                  : ink(task.status),
              shape: BoxShape.circle,
              border: Border.all(color: SimplifiedColors.surface, width: 3),
            ),
            child: Text(
              glyph,
              style: const TextStyle(
                color: SimplifiedColors.surface,
                fontSize: 13,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A chip's text, with a check beside it once it is the one chosen.
class SimplifiedChipLabel extends StatelessWidget {
  const SimplifiedChipLabel(
    this.text, {
    super.key,
    required this.selected,
    required this.onDark,
  });

  final String text;
  final bool selected;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          text,
          style: SimplifiedStyle.label(
            SimplifiedStyle.caption,
            color: onDark ? SimplifiedColors.surface : SimplifiedColors.ink,
          ),
        ),
        if (selected) ...<Widget>[
          const SizedBox(width: 6),
          const ExcludeSemantics(child: Icon(ActionIcons.check, size: 18)),
        ],
      ],
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
            icon: appointmentKindIcon(task.appointment!.kind),
            background: CareVisuals.appointmentTile,
            size: size,
          );
  }
}
