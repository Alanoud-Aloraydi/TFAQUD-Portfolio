import 'package:app/core/constants/app_colors.dart';
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
    final TextTheme text = Theme.of(context).textTheme;
    final Widget content = switch (state.accountLoad) {
      AccountLoad.loaded => Text(
        state.fullName ?? '',
        style: text.bodyLarge,
      ),
      AccountLoad.loading => const Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      AccountLoad.failed => Row(
        children: <Widget>[
          Flexible(
            child: Text(
              context.tr('circles.name_failed'),
              style: text.bodyMedium?.copyWith(color: AppColors.dangerInk),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.tr('auth.retry'))),
        ],
      ),
    };
    return ReadOnlyField(
      label: context.tr('circles.name'),
      note: context.tr('circles.from_account'),
      child: content,
    );
  }
}
