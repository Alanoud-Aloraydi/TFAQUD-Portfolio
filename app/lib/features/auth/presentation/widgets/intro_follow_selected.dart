import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/intro_person.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The person on show, picked.
class IntroFollowSelected extends StatelessWidget {
  const IntroFollowSelected({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppSemanticColors.selectedSurface,
        shape: AppRadius.shape(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: IntroPerson(
          initial: context.tr('intro.demo.mother_initial'),
          color: AppSemanticColors.surfaceAttention,
          size: 44,
          name: context.tr('intro.demo.mother'),
          note: context.tr('intro.demo.mother_note'),
          trailing: const Icon(
            ActionIcons.checkCircle,
            size: AppSizes.icon,
            color: AppSemanticColors.statusSuccess,
          ),
        ),
      ),
    );
  }
}
