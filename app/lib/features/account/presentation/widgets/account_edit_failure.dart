import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the name editor shows when the account could not be read: why, and
/// a retry.
class AccountEditFailure extends StatelessWidget {
  const AccountEditFailure({super.key, required this.messageKey});

  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr(messageKey ?? 'error.unknown'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: context.read<AccountCubit>().load,
          child: Text(context.tr('auth.retry')),
        ),
      ],
    );
  }
}
