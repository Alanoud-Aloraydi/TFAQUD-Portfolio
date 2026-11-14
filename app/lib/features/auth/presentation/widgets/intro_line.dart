import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// The thin line between two rows of a card.
class IntroLine extends StatelessWidget {
  const IntroLine({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: AppSizes.divider,
      thickness: AppSizes.divider,
      color: AppSemanticColors.segmentTrack,
    );
  }
}
