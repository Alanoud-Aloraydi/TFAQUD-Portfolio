import 'dart:math' as math;

import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The title of a prayer row: the name at the start, then the time in a slot
/// of one width, then the task count in a slot that is kept even when empty.
/// So the times of all prayers end on one line, whatever the name, the badge
/// or the text size.
class PrayerPeriodTitle extends StatelessWidget {
  const PrayerPeriodTitle({
    super.key,
    required this.name,
    required this.time,
    required this.current,
    required this.taskCount,
  });

  final String name;
  final String time;
  final bool current;
  final int taskCount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: PrayerNameBadge(name: name, current: current),
      ),
      ClockTimeSlot(time: time),
      const SizedBox(width: AppSpacing.xs),
      SizedBox(
        width: AppSizes.iconAction,
        child: taskCount > 0 ? TaskCountBadge(count: taskCount) : null,
      ),
    ],
  );
}

/// The prayer name, with the «الحالية» badge beside it (below it when the
/// text is large and the line is full).
class PrayerNameBadge extends StatelessWidget {
  const PrayerNameBadge({super.key, required this.name, required this.current});

  final String name;
  final bool current;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(name, style: Theme.of(context).textTheme.titleMedium),
      if (current)
        StatusBadge(
          text: context.tr('today_dashboard.current_period'),
          tone: StatusTone.attention,
        ),
    ],
  );
}

/// The number of all tasks in a prayer period. It is deliberately the same
/// yellow circle for medication, measurement and appointment counts; task
/// state stays on each row instead of changing the meaning of this number.
class TaskCountBadge extends StatelessWidget {
  const TaskCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: spoken(context.tr('today_dashboard.task_count', args: ['$count'])),
    excludeSemantics: true,
    child: Container(
      width: AppSizes.iconAction,
      height: AppSizes.iconAction,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppSemanticColors.accentWarm,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppSemanticColors.textPrimary),
      ),
    ),
  );
}

/// Two times with the widest text of a 12-hour clock, one for each of
/// «ص» and «م»: the slot is as wide as the wider of them.
const List<String> _widestClockTimes = <String>['10:00', '22:00'];

/// A clock time in a slot that is the same width in every row and ends the
/// text at the end side, so a column of them lines up. Digits are tabular,
/// and the slot is measured at the current text size instead of using a
/// fixed offset, so it grows with large text.
class ClockTimeSlot extends StatelessWidget {
  const ClockTimeSlot({super.key, required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = Theme.of(context).textTheme.bodySmall!.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return SizedBox(
      width: _slotWidth(context, style),
      child: Text(
        time,
        style: style,
        textAlign: TextAlign.end,
        softWrap: false,
      ),
    );
  }
}

double _slotWidth(BuildContext context, TextStyle style) {
  final TextStyle full = DefaultTextStyle.of(context).style.merge(style);
  double widest = 0;
  for (final String sample in _widestClockTimes) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: clockText(sample), style: full),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    widest = math.max(widest, painter.width);
    painter.dispose();
  }
  return widest.ceilToDouble();
}
