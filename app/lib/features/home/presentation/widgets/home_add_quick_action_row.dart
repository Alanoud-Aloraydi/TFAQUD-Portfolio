import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The icon tile of the quick action.
const double _tile = 48;

/// The row of the quick action: the leaf tile, the two lines of text, and
/// a chevron at the end.
List<Widget> homeAddQuickActionRow(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String hint,
}) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    Container(
      width: _tile,
      height: _tile,
      decoration: ShapeDecoration(
        color: AppSemanticColors.accentLeaf,
        shape: AppRadius.shape(AppRadius.s),
      ),
      child: Icon(
        icon,
        size: AppSizes.icon,
        color: AppSemanticColors.textPrimary,
      ),
    ),
    const SizedBox(width: AppSpacing.md),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: text.titleLarge?.copyWith(
              color: AppSemanticColors.surfaceContent,
            ),
          ),
          Text(
            hint,
            style: text.bodySmall?.copyWith(
              color: AppSemanticColors.borderSubtle,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    const Icon(
      AppIcons.forward,
      size: AppSizes.iconSmall,
      color: AppSemanticColors.borderSubtle,
    ),
  ];
}
