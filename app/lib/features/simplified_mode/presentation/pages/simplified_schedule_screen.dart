import 'dart:math' as math;

import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_schedule_task_rows.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_choice.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_segmented.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snooze_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «جدول اليوم»: today's tasks in time order, under the prayer they follow.
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
        return SimplifiedPage(
          title: context.tr('simplified_mode.schedule_title'),
          children: <Widget>[
            if (day == null)
              const LoadingNote()
            else
              SimplifiedScheduleCard(
                day: day,
                state: state,
                filter: _filter,
                onFilterChanged: (value) => setState(() => _filter = value),
              ),
          ],
        );
      },
    );
  }
}

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

class SimplifiedScheduleFilters extends StatelessWidget {
  const SimplifiedScheduleFilters({
    super.key,
    required this.selected,
    required this.onChanged,
  });

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
          SimplifiedScheduleFilter(
            label: entry.value,
            selected: entry.key == selected,
            onTap: () => onChanged(entry.key),
          ),
      ],
    );
  }
}

/// One kind to filter the schedule by: a pill, dark while it is the one
/// chosen.
class SimplifiedScheduleFilter extends StatelessWidget {
  const SimplifiedScheduleFilter({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: SimplifiedStyle.touch),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? SimplifiedColors.ink : SimplifiedColors.clear,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SimplifiedColors.control, width: 1.5),
          ),
          child: Text(
            label,
            style: SimplifiedStyle.head(
              SimplifiedStyle.caption,
              color: selected ? SimplifiedColors.surface : SimplifiedColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// «متى أذكّرك؟»: the detailed mode's ruler, larger, on this mode's dark
/// ground. It scrolls when the text is large, so nothing is cut off.
class SimplifiedSnoozeScreen extends StatefulWidget {
  const SimplifiedSnoozeScreen({super.key, required this.task});

  /// The dose or measurement the patient chose to put off; appointments
  /// are not put off.
  final TodayTask task;

  @override
  State<SimplifiedSnoozeScreen> createState() => _SimplifiedSnoozeScreenState();
}

class _SimplifiedSnoozeScreenState extends State<SimplifiedSnoozeScreen> {
  /// 15 minutes to start with, as the detailed sheet, when there is room.
  int _minutes = 15;

  Future<void> _confirm(int minutes) async {
    await context.read<SimplifiedModeCubit>().snooze(
      task: widget.task,
      after: Duration(minutes: minutes),
    );
    if (mounted) context.go(Routes.simplifiedMode);
  }

  @override
  Widget build(BuildContext context) {
    final SimplifiedModeState state = context
        .watch<SimplifiedModeCubit>()
        .state;
    final int most = simplifiedSnoozeLimit(
      context,
      widget.task,
      state.day,
      state.now,
    ).inMinutes;
    final int minutes = math.min(_minutes, most);
    final DateTime at = state.now.add(Duration(minutes: minutes));
    return SimplifiedDarkPage(
      actions: SimplifiedSnoozeActions(
        onConfirm: state.saving || most <= 0 ? null : () => _confirm(minutes),
      ),
      child: SimplifiedSnoozeBody(
        minutes: minutes,
        maxMinutes: most,
        clock: context.tr(
          'reminders.snooze_at',
          args: <String>[simplifiedClockAt(context, at)],
        ),
        onChanged: (int value) => setState(() => _minutes = value),
      ),
    );
  }
}

/// How long [task] may be put off from [now]. A dose is never pushed past
/// halfway to the next dose of the same medicine, the same rule the
/// detailed mode's ruler follows; anything else has the plain limit.
Duration simplifiedSnoozeLimit(
  BuildContext context,
  TodayTask task,
  SimplifiedDay? day,
  DateTime now,
) {
  final DoseOccurrence? dose = task.dose;
  if (dose == null || day == null) return maxSnooze;
  final PatientClock clock = PatientClockScope.of(context);
  return doseSnoozeLimit(dose, day.doses, clock, now);
}
