import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/auth/presentation/widgets/auth_intro.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The words of a page: a small white pill with the step («01 · نظّم»),
/// the title and one line.
class AuthWords extends StatelessWidget {
  const AuthWords({super.key, required this.intro, required this.step});

  final AuthIntro intro;
  final int step;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: const ShapeDecoration(
            color: AppSemanticColors.surfaceContent,
            shape: StadiumBorder(),
            shadows: AppSurfaces.floatShadow,
          ),
          child: Text(
            '${step.toString().padLeft(2, '0')} · ${context.tr(intro.stepKey)}',
            style: text.labelMedium?.copyWith(
              color: AppSemanticColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(context.tr(intro.titleKey), style: text.displaySmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(intro.bodyKey),
          style: text.bodyLarge?.copyWith(
            color: AppSemanticColors.textSupporting,
          ),
        ),
      ],
    );
  }
}
