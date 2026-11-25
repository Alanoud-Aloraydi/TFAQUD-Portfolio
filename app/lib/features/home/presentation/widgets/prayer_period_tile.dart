import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The opening row of a prayer period: icon, [title] and its task rows.
class PrayerPeriodTile extends StatelessWidget {
  const PrayerPeriodTile({
    super.key,
    required this.icon,
    required this.current,
    required this.expanded,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final bool current;
  final bool expanded;
  final Widget title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: expanded,
    shape: const Border(),
    collapsedShape: const Border(),
    iconColor: AppSemanticColors.textSupporting,
    collapsedIconColor: AppSemanticColors.textSupporting,
    tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    childrenPadding: const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      0,
      AppSpacing.sm,
      AppSpacing.sm,
    ),
    leading: Icon(
      icon,
      color: current
          ? AppSemanticColors.doseDueMarker
          : AppSemanticColors.textSupporting,
    ),
    title: title,
    children: children,
  );
}

/// The rounded card of a prayer period; the period the patient is in gets a
/// warm, thicker border.
class PrayerPeriodCard extends StatelessWidget {
  const PrayerPeriodCard({
    super.key,
    required this.current,
    required this.child,
  });

  final bool current;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: AppSemanticColors.surfaceContent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.m),
      side: BorderSide(
        color: current
            ? AppSemanticColors.accentWarm
            : AppSemanticColors.transparent,
        width: current ? AppSizes.borderEmphasis : AppSizes.border,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}
