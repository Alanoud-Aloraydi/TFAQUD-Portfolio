import 'package:app/core/theme/app_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MedicationFailureView extends StatelessWidget {
  const MedicationFailureView({
    super.key,
    required this.messageKey,
    required this.onRetry,
  });

  final String messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr(messageKey), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.tr('auth.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
