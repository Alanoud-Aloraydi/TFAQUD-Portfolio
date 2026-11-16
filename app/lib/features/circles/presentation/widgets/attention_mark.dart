import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// The yellow «!»: a honey circle with an exclamation mark. It marks a
/// medical file that still has unknown answers. The text next to it says
/// what is missing, so the colour is never the only sign.
class AttentionMark extends StatelessWidget {
  const AttentionMark({super.key});

  static const double _size = AppSizes.icon;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppSemanticColors.accentWarm,
        shape: BoxShape.circle,
      ),
      child: Text(
        '!',
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: AppSemanticColors.textPrimary, height: 1),
      ),
    ),
  );
}
