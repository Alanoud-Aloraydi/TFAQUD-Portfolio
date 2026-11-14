import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_visuals.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SimplifiedScheduleTaskRow extends StatelessWidget {
  const SimplifiedScheduleTaskRow({
    super.key,
    required this.task,
    required this.circleId,
    required this.snoozed,
  });

  final TodayTask task;
  final String circleId;

  /// «سأذكّرك 2:09 مساءً» in place of the status while the task is put off.
  final String? snoozed;

  /// What the row says: the name, the time and kind, where it stands.
  static List<String> lines(
    BuildContext context,
    TodayTask task,
    String? snoozed,
  ) => <String>[
    simplifiedTaskTitle(context, task),
    _when(context, task),
    snoozed ?? _status(context, task),
  ];

  /// «6:00 مساءً · دواء».
  static String _when(BuildContext context, TodayTask task) =>
      '${simplifiedTime(context, task.time)} · '
      '${context.tr('simplified_mode.kind.${task.kind.name}')}';

  static String _status(BuildContext context, TodayTask task) =>
      context.tr('simplified_mode.status.${task.status.name}');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: lines(context, task, snoozed).join('، '),
      excludeSemantics: true,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final (Color badge, Color text, String glyph) = switch (task.status) {
      TodayTaskStatus.done => (
        SimplifiedStyle.success,
        SimplifiedStyle.success,
        '✓',
      ),
      TodayTaskStatus.next => (SimplifiedStyle.ink, SimplifiedStyle.ink, '●'),
      TodayTaskStatus.late => (
        SimplifiedStyle.attentionInk,
        SimplifiedStyle.attentionInk,
        '!',
      ),
      TodayTaskStatus.later => (
        SimplifiedStyle.control,
        SimplifiedStyle.muted,
        '○',
      ),
    };
    final String status = snoozed ?? _status(context, task);
    return Semantics(
      label:
          '${simplifiedTaskTitle(context, task)}، '
          '${simplifiedTime(context, task.time)}، $status',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: SimplifiedStyle.chip)),
        ),
        child: Row(
          children: <Widget>[
            Stack(
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
                      color: badge,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SimplifiedStyle.surface,
                        width: 3,
                      ),
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
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    simplifiedTaskTitle(context, task),
                    style: SimplifiedStyle.head(SimplifiedStyle.body),
                  ),
                  Text(
                    _when(context, task),
                    style: SimplifiedStyle.text(
                      SimplifiedStyle.body,
                      weight: AppTextTheme.medium,
                    ),
                  ),
                  Text(
                    status,
                    style: SimplifiedStyle.head(
                      SimplifiedStyle.caption,
                      color: text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
