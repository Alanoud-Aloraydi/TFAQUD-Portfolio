import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/intro_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The medicine of the next-dose card, and its time.
class IntroNextDoseMedicine extends StatelessWidget {
  const IntroNextDoseMedicine({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        const IntroTile(
          icon: CareIcons.pill,
          background: AppSemanticColors.selectedSurface,
          foreground: AppSemanticColors.statusSuccess,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.tr('intro.demo.medicine'),
                style: text.titleSmall?.copyWith(
                  color: AppSemanticColors.surfaceContent,
                ),
              ),
              Text(
                context.tr('intro.demo.medicine_note'),
                style: text.bodySmall?.copyWith(
                  color: AppSemanticColors.onInkSupporting,
                ),
              ),
            ],
          ),
        ),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: context.tr('intro.demo.medicine_time'),
                style: text.headlineLarge?.copyWith(
                  color: AppSemanticColors.surfaceContent,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: context.tr('intro.demo.evening'),
                style: text.labelSmall?.copyWith(
                  color: AppSemanticColors.onInkSupporting,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
