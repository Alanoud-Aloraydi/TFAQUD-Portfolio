import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/auth/presentation/widgets/intro_initial.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The person switcher of the top bar, closed.
class IntroFollowPill extends StatelessWidget {
  const IntroFollowPill({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String mother = context.tr('intro.demo.mother');
    return Center(
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.tight,
          AppSpacing.tight,
          AppSpacing.md,
          AppSpacing.tight,
        ),
        decoration: ShapeDecoration(
          color: AppSemanticColors.surfaceContent.withValues(alpha: 0.8),
          shape: const StadiumBorder(
            side: BorderSide(color: AppSemanticColors.surfaceContent),
          ),
          shadows: AppSurfaces.floatShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IntroInitial(
              letter: context.tr('intro.demo.mother_initial'),
              color: AppSemanticColors.surfaceAttention,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: Text(mother, style: text.titleSmall)),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              ArrowIcons.caretDown,
              size: AppSizes.iconSmall,
              color: AppSemanticColors.textSupporting,
            ),
          ],
        ),
      ),
    );
  }
}
