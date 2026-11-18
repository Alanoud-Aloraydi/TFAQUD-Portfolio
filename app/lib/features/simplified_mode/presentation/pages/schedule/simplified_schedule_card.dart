import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/pages/schedule/simplified_schedule_summary.dart';
import 'package:app/features/simplified_mode/presentation/pages/schedule/simplified_schedule_task_rows.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_filters.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
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
