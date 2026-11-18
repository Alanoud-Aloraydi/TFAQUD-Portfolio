import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The top line of the next-dose card: its name, and the time left.
class IntroNextDoseHeader extends StatelessWidget {
  const IntroNextDoseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            context.tr('intro.demo.next_dose'),
            style: text.labelSmall?.copyWith(
              color: AppSemanticColors.onInkSupporting,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusPill(
          text: context.tr('intro.demo.next_in'),
          background: AppSemanticColors.surfaceContent.withValues(alpha: 0.14),
          foreground: AppSemanticColors.surfaceContent,
        ),
      ],
    );
  }
}
