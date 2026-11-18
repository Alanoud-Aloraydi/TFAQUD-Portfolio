import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The circle switcher capsule's own content, drawn at the top of its menu:
/// the circle's name and the down chevron.
class CircleMenuAnchor extends StatelessWidget {
  const CircleMenuAnchor({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Flexible(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      const Icon(
        ArrowIcons.caretDown,
        size: AppSizes.iconSmall,
        color: AppSemanticColors.textPrimary,
      ),
    ],
  );
}
