import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/read_only_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The patient's name, read from the account and not editable ("من حسابك").
/// It shows a spinner while the names load, and a retry link when they fail.
class AccountNameField extends StatelessWidget {
  const AccountNameField({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final CreateCircleState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (state.accountLoad) {
      AccountLoad.loaded || AccountLoad.notNeeded => Text(
        state.fullName ?? '',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      AccountLoad.loading => const Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: AppSpacing.space5,
          height: AppSpacing.space5,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      AccountLoad.failed => AccountLoadFailed(
        messageKey: 'circles.name_failed',
        onRetry: onRetry,
      ),
    };
    return ReadOnlyField(
      label: context.tr('circles.name'),
      note: context.tr('circles.from_account'),
      child: content,
    );
  }
}

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
