import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The card could not be read: why, and a button that reads it again.
class EmergencyCardFailure extends StatelessWidget {
  const EmergencyCardFailure({
    super.key,
    required this.messageKey,
    required this.onRetry,
  });

  final String? messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.tr(messageKey ?? 'error.unknown'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.tr('auth.retry')),
          ),
        ],
      ),
    );
  }
}
