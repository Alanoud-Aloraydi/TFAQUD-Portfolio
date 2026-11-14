import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// The green round check of a recorded dose.
class IntroDone extends StatelessWidget {
  const IntroDone({super.key});

  static const double _size = 28;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: const ShapeDecoration(
        color: AppSemanticColors.statusSuccess,
        shape: CircleBorder(),
      ),
      child: const Icon(
        AppIcons.check,
        size: AppSizes.iconSmall - 4,
        color: AppSemanticColors.surfaceContent,
      ),
    );
  }
}
