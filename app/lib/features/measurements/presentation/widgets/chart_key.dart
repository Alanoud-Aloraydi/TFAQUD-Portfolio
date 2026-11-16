import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

class ChartKey extends StatelessWidget {
  const ChartKey(this.color, this.label, {super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          // A pale band still shows its edge.
          border: Border.all(color: AppSemanticColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: const SizedBox(width: 12, height: 8),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
