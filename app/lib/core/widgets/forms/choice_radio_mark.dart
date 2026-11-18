import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// The radio mark at the end of a [ChoiceCard]: a ring, filled when
/// selected.
class ChoiceRadioMark extends StatelessWidget {
  const ChoiceRadioMark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppSemanticColors.textPrimary
              : AppSemanticColors.borderControlBase,
          width: AppSizes.borderEmphasis,
        ),
      ),
      child: selected
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppSemanticColors.textPrimary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
