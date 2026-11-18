import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The last row of the list: add a person.
class IntroFollowAdd extends StatelessWidget {
  const IntroFollowAdd({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: const ShapeDecoration(
              color: AppSemanticColors.surfaceContent,
              shape: CircleBorder(
                side: BorderSide(
                  color: AppSemanticColors.borderControlBase,
                  width: AppSizes.borderEmphasis,
                ),
              ),
            ),
            child: const Icon(
              ActionIcons.plus,
              size: AppSizes.iconSmall,
              color: AppSemanticColors.textSupporting,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.tr('intro.demo.add_person'),
              style: text.titleSmall?.copyWith(
                color: AppSemanticColors.textSupporting,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
