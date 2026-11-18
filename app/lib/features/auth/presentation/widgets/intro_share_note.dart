import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/auth/presentation/widgets/intro_done.dart';
import 'package:app/features/auth/presentation/widgets/intro_first_letter.dart';
import 'package:app/features/auth/presentation/widgets/intro_initial.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The dark note over the members: one of them logged a reading.
class IntroShareNote extends StatelessWidget {
  const IntroShareNote({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: AppRadius.shape(AppRadius.m),
        shadows: AppSurfaces.floatShadow,
      ),
      child: Row(
        children: <Widget>[
          IntroInitial(
            letter: firstLetter(context.tr('intro.demo.khalid')),
            color: AppSemanticColors.surfaceAttention,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: context.tr('intro.demo.khalid'),
                    style: const TextStyle(fontWeight: AppTextTheme.bold),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(text: context.tr('intro.demo.khalid_logged')),
                ],
              ),
              style: text.bodyMedium?.copyWith(
                color: AppSemanticColors.surfaceContent,
              ),
            ),
          ),
          const IntroDone(),
        ],
      ),
    );
  }
}
