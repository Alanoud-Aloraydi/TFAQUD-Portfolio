import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// One line of a card's opened details: «أضافه: سارة». With a [label] the
/// label and value share the line; without one it is a sentence.
class PlanDetailLine extends StatelessWidget {
  const PlanDetailLine(this.value, {super.key, this.label});

  final String value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final String? label = this.label;
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: label == null
          ? Text(value, style: style)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Text(label, style: style)),
                Expanded(child: Text(value, style: style)),
              ],
            ),
    );
  }
}
