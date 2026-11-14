import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// The small grey label at the start of a form row. It reads like a hint, so
/// the value or the typed text, set larger in ink, is what stands out. Every
/// label has the same column width, so values line up from row to row.
class InsetRowLabel extends StatelessWidget {
  const InsetRowLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.formLabel,
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
