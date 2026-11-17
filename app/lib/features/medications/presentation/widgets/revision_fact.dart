import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// One labelled line of a change in «سجل التعديلات»: a small grey [label]
/// over its [child], as the medicine's own facts read.
class RevisionFact extends StatelessWidget {
  const RevisionFact({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          DefaultTextStyle.merge(style: text.bodyLarge, child: child),
        ],
      ),
    );
  }
}
