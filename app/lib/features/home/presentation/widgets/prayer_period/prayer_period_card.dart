import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

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
