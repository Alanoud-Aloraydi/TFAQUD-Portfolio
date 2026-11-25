import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_schedule_task_rows.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_filters.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The day's progress, the kind filter and the tasks of [day] in time
/// order, under the prayer they follow.
class SimplifiedScheduleCard extends StatelessWidget {
  const SimplifiedScheduleCard({
    super.key,
    required this.day,
    required this.state,
    required this.filter,
    required this.onFilterChanged,
  });

  final SimplifiedDay day;
  final SimplifiedModeState state;

  /// Null shows every kind («الكل»).
  final TodayTaskKind? filter;
  final ValueChanged<TodayTaskKind?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final TodaySchedule schedule = state.schedule!;
    final List<TodayTask> shown = <TodayTask>[
      for (final TodayTask task in schedule.tasks)
        if (filter == null || task.kind == filter) task,
    ];
    return SimplifiedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SimplifiedScheduleSummary(schedule: schedule),
          const SizedBox(height: 12),
          SimplifiedScheduleFilters(
            selected: filter,
            onChanged: onFilterChanged,
          ),
          if (shown.isEmpty) ...<Widget>[
            const SizedBox(height: SimplifiedStyle.gap),
            Text(
              context.tr('simplified_mode.nothing_to_show'),
              style: SimplifiedStyle.text(SimplifiedStyle.body),
            ),
          ],
          ...simplifiedScheduleTaskRows(
            context,
            day: day,
            schedule: schedule,
            state: state,
            shown: shown,
          ),
        ],
      ),
    );
  }
}

/// How many of the day's tasks are done.
class SimplifiedScheduleSummary extends StatelessWidget {
  const SimplifiedScheduleSummary({super.key, required this.schedule});

  final TodaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(
        'simplified_mode.done_count_short',
        args: <String>['${schedule.doneCount}', '${schedule.total}'],
      ),
      style: SimplifiedStyle.text(
        SimplifiedStyle.caption,
        weight: AppTextTheme.semibold,
      ),
    );
  }
}
