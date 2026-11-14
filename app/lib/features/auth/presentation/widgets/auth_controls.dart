import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/auth_dots.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The bottom of the first pages: «تخطي», the dots, and «التالي».
class AuthControls extends StatelessWidget {
  const AuthControls({
    super.key,
    required this.count,
    required this.current,
    required this.onSkip,
    required this.onNext,
  });

  final int count;
  final int current;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: AppSemanticColors.textSupporting,
            minimumSize: const Size(AppSizes.touch, AppSizes.touch),
          ),
          child: Text(context.tr('intro.skip')),
        ),
        Expanded(
          child: Center(
            child: AuthDots(count: count, current: current),
          ),
        ),
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: AppSemanticColors.textPrimary,
            foregroundColor: AppSemanticColors.surfaceContent,
            shape: const StadiumBorder(),
            minimumSize: const Size(AppSizes.button, AppSizes.button),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(context.tr('intro.next')),
              const SizedBox(width: AppSpacing.sm),
              const Icon(AppIcons.next, size: AppSizes.iconSmall),
            ],
          ),
        ),
      ],
    );
  }
}
