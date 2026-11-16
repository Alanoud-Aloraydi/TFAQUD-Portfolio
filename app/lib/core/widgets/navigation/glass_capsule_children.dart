import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// What sits in a glass capsule button: an optional leading circle, the
/// label cut short at one line, and the icon that says it opens something.
List<Widget> glassCapsuleChildren({
  required String label,
  required IconData icon,
  required Widget? leading,
  required VoidCallback? onLeadingPressed,
  required TextTheme text,
}) {
  return <Widget>[
    if (leading != null) ...<Widget>[
      GestureDetector(onTap: onLeadingPressed, child: leading),
      const SizedBox(width: AppSpacing.xs),
    ],
    Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.titleLarge,
      ),
    ),
    const SizedBox(width: AppSpacing.xs),
    Icon(icon, size: AppSizes.iconSmall, color: AppSemanticColors.textPrimary),
  ];
}
