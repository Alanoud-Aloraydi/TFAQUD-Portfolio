import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The account could not be read: [messageKey] says so, beside a retry
/// link. The page still works without the account.
class AccountLoadFailed extends StatelessWidget {
  const AccountLoadFailed({
    super.key,
    this.messageKey = 'circles.account_failed',
    required this.onRetry,
  });

  final String messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            context.tr(messageKey),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppSemanticColors.statusError),
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(context.tr('auth.retry'))),
      ],
    );
  }
}
