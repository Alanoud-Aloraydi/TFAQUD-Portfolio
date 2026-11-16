import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// One mark: a long one with its words under it, or a short one between.
class RulerTick extends StatelessWidget {
  const RulerTick({super.key, required this.major, this.label});

  final bool major;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: major ? 2 : 1,
          height: major ? 26 : 14,
          color: major
              ? AppSemanticColors.textPrimary
              : AppSemanticColors.borderControlBase,
        ),
        const Spacer(),
        // A number is wider than its mark: it overflows to both sides.
        SizedBox(
          height: 18,
          child: label != null
              ? OverflowBox(
                  maxWidth: 40,
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppSemanticColors.textSupporting),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
