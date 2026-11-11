import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a list shows when it could not load: the message and «أعد المحاولة».
/// The same in «اليوم», «الخطة» and «السجل».
class RetryView extends StatelessWidget {
  const RetryView({super.key, required this.messageKey, required this.onRetry});

  /// A key in assets/translations.
  final String messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
