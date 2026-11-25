import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// One plan: an icon tile, the name and what it does, and a chevron.
class HomeAddPlanOption extends StatelessWidget {
  const HomeAddPlanOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: spoken('$title، $hint'),
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: MergeSemantics(
          child: Row(
            children: homeAddPlanOptionRow(
              context,
              icon: icon,
              title: title,
              hint: hint,
            ),
          ),
        ),
      ),
    ),
  );
}

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
      ArrowIcons.forward,
      size: AppSizes.iconSmall,
      color: AppSemanticColors.borderControlBase,
    ),
  ];
}
