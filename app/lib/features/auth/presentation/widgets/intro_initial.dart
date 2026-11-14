import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// A round letter on a soft color.
class IntroInitial extends StatelessWidget {
  const IntroInitial({
    super.key,
    required this.letter,
    required this.color,
    required this.size,
  });

  final String letter;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: color, shape: const CircleBorder()),
      child: Text(
        letter,
        style: (size < AppSizes.avatar ? text.labelMedium : text.titleMedium)
            ?.copyWith(
              color: AppSemanticColors.textPrimary,
              fontWeight: AppTextTheme.bold,
            ),
      ),
    );
  }
}
