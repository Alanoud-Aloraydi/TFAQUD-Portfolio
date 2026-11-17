import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/expand_reveal.dart';
import 'package:app/core/widgets/layout/group_header.dart';
import 'package:flutter/material.dart';

/// Records gathered under a heading that folds away, as «يحتاج انتباهك»
/// does: [title], [count], «إخفاء» or «عرض», all one button; then [child].
class CollapsibleGroup extends StatelessWidget {
  const CollapsibleGroup({
    super.key,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      // The same surface as «يحتاج انتباهك»: both gather cards under a
      // heading that folds, so they are one thing to the eye.
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceFold,
        border: Border.all(color: AppSemanticColors.accentLeaf),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GroupHeader(
            title: title,
            expanded: expanded,
            onToggle: onToggle,
            count: count,
          ),
          ExpandReveal(
            open: expanded,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
