import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_period_header.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
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
