import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_filters.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_period_header.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «جدول اليوم»: today's medicines, measurements and appointments in time
/// order, under the prayer they follow, each with where it stands.
class SimplifiedScheduleScreen extends StatefulWidget {
  const SimplifiedScheduleScreen({super.key});

  @override
  State<SimplifiedScheduleScreen> createState() =>
      _SimplifiedScheduleScreenState();
}

class _SimplifiedScheduleScreenState extends State<SimplifiedScheduleScreen> {
  /// Null shows every kind («الكل»).
  TodayTaskKind? _filter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SimplifiedModeCubit, SimplifiedModeState>(
      builder: (context, state) {
        final SimplifiedDay? day = state.day;
        final TodaySchedule? schedule = state.schedule;
        final String summary = schedule == null
            ? ''
            : context.tr(
                'simplified_mode.done_count_short',
                args: <String>['${schedule.doneCount}', '${schedule.total}'],
              );
        final List<TodayTask> shown = <TodayTask>[
          for (final TodayTask task in schedule?.tasks ?? const <TodayTask>[])
            if (_filter == null || task.kind == _filter) task,
        ];
        return SimplifiedPage(
          title: context.tr('simplified_mode.schedule_title'),
          children: <Widget>[
            if (day == null)
              const Center(child: CircularProgressIndicator())
            else
              SimplifiedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      summary,
                      style: SimplifiedStyle.text(
                        SimplifiedStyle.caption,
                        weight: AppTextTheme.semibold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SimplifiedScheduleFilters(
                      selected: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                    if (shown.isEmpty) ...<Widget>[
                      const SizedBox(height: SimplifiedStyle.gap),
                      Text(
                        context.tr('simplified_mode.nothing_to_show'),
                        style: SimplifiedStyle.text(SimplifiedStyle.body),
                      ),
                    ],
                    for (final (PrayerPeriod?, List<TodayTask>) group
                        in groupByPeriod(shown, day.prayers)) ...<Widget>[
                      if (group.$1 case final PrayerPeriod period) ...<Widget>[
                        const SizedBox(height: SimplifiedStyle.gap),
                        SimplifiedSchedulePeriodHeader(period: period),
                      ],
                      for (final TodayTask task in group.$2)
                        SimplifiedScheduleTaskRow(
                          task: task,
                          circleId: day.circleId,
                          snoozed: simplifiedSnoozed(
                            context,
                            state.snoozes,
                            day.circleId,
                            task,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
