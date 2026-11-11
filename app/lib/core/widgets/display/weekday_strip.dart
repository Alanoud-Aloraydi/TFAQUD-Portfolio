import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/weekdays.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The days a plan repeats on, as a week of small circles. All seven days
/// show as one «كل يوم» label instead, the same words the selector uses.
class WeekdayStrip extends StatelessWidget {
  const WeekdayStrip({super.key, required this.days});

  final Iterable<int> days;

  @override
  Widget build(BuildContext context) {
    if (isEveryDay(days)) {
      return CompactStatusBadge(
        text: context.tr('weekday_picker.every_day'),
        background: AppSemanticColors.selectedSurface,
        foreground: AppSemanticColors.textPrimary,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final int day in weekOrder) ...<Widget>[
          _Dot(
            label: context.tr('medications.weekday_short.$day'),
            on: days.contains(day),
          ),
          if (day != weekOrder.last) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: on
          ? AppSemanticColors.selectedSurface
          : AppSemanticColors.surfaceContent,
      border: on ? null : Border.all(color: AppSemanticColors.borderSubtle),
      borderRadius: BorderRadius.circular(AppRadius.capsule),
    ),
    child: SizedBox.square(
      dimension: 20,
      child: Center(
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    ),
  );
}
