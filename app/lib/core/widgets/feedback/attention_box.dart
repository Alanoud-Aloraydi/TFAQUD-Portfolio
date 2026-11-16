import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/expand_reveal.dart';
import 'package:app/core/widgets/layout/group_header.dart';
import 'package:flutter/material.dart';

/// Shared «يحتاج انتباهك» box: a warning icon, a title, an optional item
/// count, and [child] below — collapsible when [onToggle] is given.
class AttentionBox extends StatelessWidget {
  const AttentionBox({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.expanded = true,
    this.onToggle,
  });

  final String title;
  final Widget child;
  final int? count;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final bool collapsible = onToggle != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        // Not a yellow wash, and not the page's own colour either: that
        // left the group invisible at 1.00 against the canvas. This violet
        // is the plan's tint one step down, so the group is seen and the
        // white cards on it stand out more than before, not less.
        color: AppSemanticColors.surfaceGroup,
        border: Border.all(color: AppSemanticColors.accentLeaf),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              bottom: collapsible ? AppSpacing.tight : 0,
            ),
            child: GroupHeader(
              title: title,
              expanded: expanded,
              onToggle: onToggle,
              count: count,
              icon: TafaqodPhosphorIcons.warning,
              ink: AppSemanticColors.statusWarning,
              countFill: AppSemanticColors.accentWarm,
            ),
          ),
          // Slides down from the title as it opens, like a plan's details.
          if (collapsible)
            ExpandReveal(open: expanded, child: child)
          else
            child,
        ],
      ),
    );
  }
}
