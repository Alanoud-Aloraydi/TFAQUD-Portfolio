import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_task_status.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_visuals.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SimplifiedScheduleTaskRow extends StatelessWidget {
  const SimplifiedScheduleTaskRow({
    super.key,
    required this.task,
    required this.day,
    required this.now,
    required this.snoozed,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// The patient's moment, for how long a task has been late.
  final DateTime now;

  /// «سأذكّرك 2:09 مساءً» in place of the status while the task is put off.
  final String? snoozed;

  /// What the row says: the name, the time and kind, how to take it, and
  /// where it stands.
  static List<String> lines(
    BuildContext context,
    TodayTask task,
    SimplifiedDay day,
    DateTime now,
    String? snoozed,
  ) => <String>[
    simplifiedTaskTitle(context, task),
    _when(context, task),
    ?_how(context, task, day),
    snoozed ?? simplifiedTaskStatus(context, task, day, now),
  ];

  /// How it is taken: «حبة واحدة · مع الأكل», the same words the cards
  /// show, so the schedule says enough to act on without opening a task.
  static String? _how(BuildContext context, TodayTask task, SimplifiedDay day) {
    final List<String> parts = <String>[
      if (task.kind == TodayTaskKind.medication)
        simplifiedDoseAmount(context, task.dose!),
      ...simplifiedTaskChips(context, task, day),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// «6:00 مساءً · دواء».
  static String _when(BuildContext context, TodayTask task) =>
      '${simplifiedTime(context, task.time)} · '
      '${context.tr('simplified_mode.kind.${task.kind.name}')}';

  @override
  Widget build(BuildContext context) {
    // One stop for the whole row. The «·» between the time and the kind
    // is a pause when read aloud, not a word.
    return Semantics(
      label: spoken(lines(context, task, day, now, snoozed).join('، ')),
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
    final String status =
        snoozed ?? simplifiedTaskStatus(context, task, day, now);
    final String? how = _how(context, task, day);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SimplifiedStyle.chip)),
      ),
      child: Row(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              TaskThumb(task: task, circleId: day.circleId),
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
                if (how != null)
                  Text(
                    how,
                    style: SimplifiedStyle.text(
                      SimplifiedStyle.caption,
                      color: SimplifiedStyle.muted,
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
    );
  }
}
