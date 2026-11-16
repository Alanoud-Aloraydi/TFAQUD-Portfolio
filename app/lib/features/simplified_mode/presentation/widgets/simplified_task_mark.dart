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
    TodayTaskStatus.done => SimplifiedStyle.success,
    TodayTaskStatus.next => SimplifiedStyle.ink,
    TodayTaskStatus.late => SimplifiedStyle.attentionInk,
    TodayTaskStatus.later => SimplifiedStyle.muted,
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
                  ? SimplifiedStyle.control
                  : ink(task.status),
              shape: BoxShape.circle,
              border: Border.all(color: SimplifiedStyle.surface, width: 3),
            ),
            child: Text(
              glyph,
              style: const TextStyle(
                color: SimplifiedStyle.surface,
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
