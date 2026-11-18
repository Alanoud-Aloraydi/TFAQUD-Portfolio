import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The title and the optional message of an alert, centered.
class AppAlertText extends StatelessWidget {
  const AppAlertText({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    // Text 16 from the panel's edge: 12 + 4.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        children: <Widget>[
          Text(title, textAlign: TextAlign.center, style: text.titleLarge),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(message!, textAlign: TextAlign.center, style: text.bodyMedium),
          ],
        ],
      ),
    );
  }
}
