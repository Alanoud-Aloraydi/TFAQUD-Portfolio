import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// A line of text under the plan form: the hint about when an edit starts,
/// or the reason the form was not saved.
class MeasurementPlanFormNote extends StatelessWidget {
  const MeasurementPlanFormNote({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Text(text, style: style),
  );
}
