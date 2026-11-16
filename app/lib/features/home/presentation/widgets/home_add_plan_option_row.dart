import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The icon tile of a plan option.
const double _tile = AppSizes.avatar;

/// The row of one plan: the icon tile, the name and what it does, and a
/// chevron at the end.
List<Widget> homeAddPlanOptionRow(
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
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(AppRadius.s),
      ),
      child: Icon(
        icon,
        size: AppSizes.iconSmall,
        color: AppSemanticColors.textSupporting,
      ),
    ),
    const SizedBox(width: AppSpacing.md),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: text.titleSmall),
          Text(
            hint,
            style: text.bodySmall?.copyWith(
              color: AppSemanticColors.textSupporting,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    const Icon(
      AppIcons.forward,
      size: AppSizes.iconSmall,
      color: AppSemanticColors.borderControlBase,
    ),
  ];
}
