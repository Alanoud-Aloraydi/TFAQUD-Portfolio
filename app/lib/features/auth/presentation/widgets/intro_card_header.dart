import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The bold title of a card, and a small note at its end.
class IntroCardHeader extends StatelessWidget {
  const IntroCardHeader({super.key, required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? small = note;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(title, style: text.titleMedium)),
          if (small != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Text(small, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}
