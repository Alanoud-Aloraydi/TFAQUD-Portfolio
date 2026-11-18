import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// The phone in a circle at the start of a sent request's row.
class SentRequestIcon extends StatelessWidget {
  const SentRequestIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppSemanticColors.selectedSurface,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        PeopleIcons.phone,
        size: AppSizes.iconSmall,
        color: AppSemanticColors.textPrimary,
      ),
    );
  }
}
