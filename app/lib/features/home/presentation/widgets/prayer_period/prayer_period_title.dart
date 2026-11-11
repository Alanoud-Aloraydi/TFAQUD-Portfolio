import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/clock_time_slot.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/prayer_name_badge.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/task_count_badge.dart';
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
