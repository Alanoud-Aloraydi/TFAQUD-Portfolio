import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/next_task_look.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_settings_tile_colors.dart';

/// The top of the next task's card: the round icon of its kind, then which
/// kind of task it is over its name.
class NextTaskHeader extends StatelessWidget {
  const NextTaskHeader({super.key, required this.task});

  final NextTask task;

  @override
  Widget build(BuildContext context) {
    final title = nextTaskTitle(context, task);
    final (String headerKey, IconData icon, Color iconBackground) =
        nextTaskLook(task);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: AppSizes.avatar,
            height: AppSizes.avatar,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppSizes.iconSmall,
              color: AppSettingsTileColors.onTile,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(headerKey),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ],
    );
  }
}
