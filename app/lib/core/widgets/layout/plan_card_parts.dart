/// The parts the plan cards of «الخطة» share, so a medicine, a
/// measurement and an appointment look and work the same: the pencil
/// beside the status at the top ([PlanEditButton]), and the line at the
/// bottom that opens the details ([PlanDetailsToggle]).
library;

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The pencil that opens the edit form, beside the card's status.
class PlanEditButton extends StatelessWidget {
  const PlanEditButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  final VoidCallback onPressed;

  /// What the pencil edits, for the screen reader: «تعديل بيانات الدواء».
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: const Icon(AppIcons.pencil),
    tooltip: tooltip,
  );
}

/// The card's last line: on the start side, when the plan starts or
/// started ([start], «بدأ في 7 نوفمبر 2026»); on the end side, «تفاصيل
/// الدواء» ([label]) with its arrow last, which opens and closes the
/// details. The whole line is the button.
class PlanDetailsToggle extends StatelessWidget {
  const PlanDetailsToggle({
    super.key,
    required this.label,
    required this.expanded,
    required this.onTap,
    this.start,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;
  final String? start;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? start = this.start;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
          child: Row(
            children: [
              if (start != null) ...[
                const Icon(CupertinoIcons.calendar, size: AppSizes.iconSmall),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(start, style: text.bodySmall)),
              ] else
                const Spacer(),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: text.labelLarge),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                expanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: AppSizes.iconSmall,
                color: AppSemanticColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
