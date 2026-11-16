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
        // The simplified mode's cream: lighter than the honey of the
        // badges, so the white cards on it stand out and it does not shout.
        color: AppSemanticColors.surfaceAttentionGroup,
        border: Border.all(color: AppSemanticColors.borderAttentionGroup),
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
