import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_thumb.dart';
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
