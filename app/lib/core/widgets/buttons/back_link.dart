import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The "رجوع" link at the top of a step page.
/// The back chevron (SF chevron.backward, AppIcons.back) turns to
/// point right on an Arabic (right-to-left) screen, as iOS draws it.
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(AppIcons.back, size: AppSizes.iconSmall),
        label: Text(context.tr('common.back')),
        // No padding on the start side: the chevron sits on the page margin,
        // on the same line as the title under it.
        style: TextButton.styleFrom(
          foregroundColor: AppSemanticColors.textPrimary,
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        ),
      ),
    );
  }
}
