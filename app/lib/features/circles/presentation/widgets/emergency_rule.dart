import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// A thin line between the parts of the card, 12 above and below.
class EmergencyRule extends StatelessWidget {
  const EmergencyRule({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(
        height: AppSizes.divider,
        color: AppSemanticColors.segmentTrack,
      ),
    );
  }
}
