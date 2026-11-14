import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/features/auth/presentation/widgets/intro_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The dark card of the next dose: the medicine, its time, and a bar of the
/// time left.
class IntroNextDoseCard extends StatelessWidget {
  const IntroNextDoseCard({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: AppRadius.shape(AppRadius.l),
        shadows: AppSurfaces.floatShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
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
                background: AppSemanticColors.surfaceContent.withValues(
                  alpha: 0.14,
                ),
                foreground: AppSemanticColors.surfaceContent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              const IntroTile(
                icon: AppIcons.pill,
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
          ),
          const SizedBox(height: AppSpacing.md),
          // The time left until the dose: the bar fills from the start side.
          Container(
            height: _bar,
            decoration: ShapeDecoration(
              color: AppSemanticColors.surfaceContent.withValues(alpha: 0.14),
              shape: const StadiumBorder(),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: const FractionallySizedBox(
              widthFactor: 0.72,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: AppSemanticColors.actionPrimary,
                  shape: StadiumBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _bar = 6;
}
