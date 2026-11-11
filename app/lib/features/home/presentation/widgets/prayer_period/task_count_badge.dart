import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The number of all tasks in a prayer period. It is deliberately the same
/// yellow circle for medication, measurement and appointment counts; task
/// state stays on each row instead of changing the meaning of this number.
class TaskCountBadge extends StatelessWidget {
  const TaskCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('today_dashboard.task_count', args: ['$count']),
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
