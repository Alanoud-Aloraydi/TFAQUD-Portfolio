import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_controls.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_visuals.dart';
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
          listen: <String>[
            summary,
            for (final TodayTask task in shown)
              '${simplifiedTime(context, task.time)} '
                  '${simplifiedTaskTitle(context, task)} '
                  '${context.tr('simplified_mode.status.${task.status.name}')}',
          ],
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
                    _Filters(
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
                        _PeriodHeader(period: period),
                      ],
                      for (final TodayTask task in group.$2)
                        _TaskRow(task: task, circleId: day.circleId),
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

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onChanged});

  final TodayTaskKind? selected;
  final ValueChanged<TodayTaskKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    final Map<TodayTaskKind?, String> filters = <TodayTaskKind?, String>{
      null: context.tr('simplified_mode.filter.all'),
      TodayTaskKind.medication: context.tr('simplified_mode.filter.medication'),
      TodayTaskKind.measurement: context.tr(
        'simplified_mode.filter.measurement',
      ),
      TodayTaskKind.appointment: context.tr(
        'simplified_mode.filter.appointment',
      ),
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final MapEntry<TodayTaskKind?, String> entry in filters.entries)
          Semantics(
            button: true,
            selected: entry.key == selected,
            child: InkWell(
              onTap: () => onChanged(entry.key),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: entry.key == selected
                      ? SimplifiedStyle.ink
                      : SimplifiedStyle.clear,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: SimplifiedStyle.control,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: SimplifiedStyle.head(
                    SimplifiedStyle.caption,
                    color: entry.key == selected
                        ? SimplifiedStyle.surface
                        : SimplifiedStyle.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({required this.period});

  final PrayerPeriod period;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: SimplifiedStyle.chip,
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

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.circleId});

  final TodayTask task;
  final String circleId;

  @override
  Widget build(BuildContext context) {
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
    final String status = context.tr(
      'simplified_mode.status.${task.status.name}',
    );
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
                    '${simplifiedTime(context, task.time)} · '
                    '${context.tr('simplified_mode.kind.${task.kind.name}')}',
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
