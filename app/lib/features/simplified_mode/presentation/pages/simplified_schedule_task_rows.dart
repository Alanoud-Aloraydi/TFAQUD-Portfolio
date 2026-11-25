import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/features/simplified_mode/domain/entities/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reading_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_extras.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:flutter/material.dart';

/// The [shown] tasks of [day], each group under the prayer it follows.
List<Widget> simplifiedScheduleTaskRows(
  BuildContext context, {
  required SimplifiedDay day,
  required TodaySchedule schedule,
  required SimplifiedModeState state,
  required List<TodayTask> shown,
}) {
  return <Widget>[
    for (final (PrayerPeriod?, List<TodayTask>) group in groupByPeriod(
      shown,
      day.prayers,
    )) ...<Widget>[
      if (group.$1 case final PrayerPeriod period) ...<Widget>[
        const SizedBox(height: SimplifiedStyle.gap),
        SimplifiedSchedulePeriodHeader(period: period),
      ],
      for (final TodayTask task in group.$2)
        SimplifiedScheduleTaskRow(
          task: task,
          day: day,
          schedule: schedule,
          now: state.now,
          snoozed: simplifiedSnoozed(
            context,
            state.snoozes,
            day.circleId,
            task,
          ),
        ),
    ],
  ];
}

class SimplifiedSchedulePeriodHeader extends StatelessWidget {
  const SimplifiedSchedulePeriodHeader({super.key, required this.period});

  final PrayerPeriod period;

  /// What the header says: «بعد المغرب. المساء».
  static List<String> lines(BuildContext context, PrayerPeriod period) =>
      <String>[
        simplifiedPeriod(context, period),
        simplifiedPeriodHint(context, period),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: SimplifiedColors.chip,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: <Widget>[
          Text(
            simplifiedPeriod(context, period),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          Text(
            simplifiedPeriodHint(context, period),
            style: SimplifiedStyle.text(SimplifiedStyle.caption),
          ),
        ],
      ),
    );
  }
}

class SimplifiedScheduleTaskRow extends StatelessWidget {
  const SimplifiedScheduleTaskRow({
    super.key,
    required this.task,
    required this.day,
    required this.now,
    required this.snoozed,
    required this.schedule,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// The patient's moment, for how long a task has been late.
  final DateTime now;

  /// «سأذكّرك 2:09 مساءً» in place of the status while the task is put off.
  final String? snoozed;

  /// Says whether the task can still be recorded, by the same rule «اليوم»
  /// follows.
  final TodaySchedule schedule;

  /// A task the patient can answer from here, as in the detailed mode: a
  /// dose, a reading or a visit opens its reminder, from an hour before
  /// its time until it is recorded.
  bool get _recordable => schedule.canRecord(task);

  @override
  Widget build(BuildContext context) {
    // One stop for the whole row.
    return Semantics(
      label: spoken(
        simplifiedScheduleLines(context, task, day, now, snoozed).join('، '),
      ),
      button: _recordable,
      onTap: _recordable
          ? () => openSimplifiedTask(context, task, day.circleId)
          : null,
      excludeSemantics: true,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final Widget row = SimplifiedScheduleTaskLine(
      task: task,
      day: day,
      now: now,
      snoozed: snoozed,
    );
    if (!_recordable) return row;
    return InkWell(
      onTap: () => openSimplifiedTask(context, task, day.circleId),
      child: row,
    );
  }
}
