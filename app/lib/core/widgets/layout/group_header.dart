import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/fold_affordance.dart';
import 'package:app/core/widgets/layout/group_title.dart';
import 'package:flutter/material.dart';

/// The line a folding group opens with: an optional [icon], the [title],
/// how many are inside, and «إظهار» or «إخفاء» with its caret. The whole
/// line is one stop for a screen reader and one button, so the person
/// never hunts for a small arrow.
///
/// Shared by «يحتاج انتباهك» and the folded groups of «السجل»: they are
/// the same thing in different words, and were the same code twice.
class GroupHeader extends StatelessWidget {
  const GroupHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.count,
    this.icon,
    this.ink,
    this.countFill,
  });

  final String title;
  final bool expanded;

  /// Null leaves the group always open, and the line is not a button.
  final VoidCallback? onToggle;
  final int? count;
  final IconData? icon;

  /// The title, the icon and the caret; the theme's own colour when null.
  final Color? ink;
  final Color? countFill;

  /// How far a 17-point glyph's drawing sits inside its square.
  static const double _glyphMargin = 1.5;

  @override
  Widget build(BuildContext context) {
    final bool collapsible = onToggle != null;
    return MergeSemantics(
      child: Semantics(
        button: collapsible,
        expanded: collapsible ? expanded : null,
        onTap: onToggle,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadius.m),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touch),
            child: Row(
              children: <Widget>[
                if (icon case final IconData shown) ...<Widget>[
                  // The triangle sits inside its square: moved by that
                  // margin, its edge lines up with the cards under it.
                  Transform.translate(
                    offset: Offset(
                      Directionality.of(context) == TextDirection.rtl
                          ? _glyphMargin
                          : -_glyphMargin,
                      0,
                    ),
                    child: Icon(shown, color: ink, size: 17),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                // The title takes the room, so «إخفاء» sits at the far
                // edge, over the cards' own edge.
                Expanded(
                  child: GroupTitle(
                    title: title,
                    count: count,
                    ink: ink,
                    countFill: countFill,
                  ),
                ),
                if (collapsible) FoldAffordance(expanded: expanded, ink: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
