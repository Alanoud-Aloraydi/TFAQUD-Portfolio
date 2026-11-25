import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/pages/account_edit_flow.dart';
import 'package:app/features/account/presentation/widgets/account_content.dart';
import 'package:app/features/account/presentation/widgets/account_edit_fields.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Full-screen account name editor; the verified phone number stays read-only.
class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen>
    with AccountEditFlow<AccountEditScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: BlocConsumer<AccountCubit, AccountState>(
          listener: (context, state) {
            if (state.sessionEnded) {
              context.go(Routes.auth);
              return;
            }
            fill(state.account);
          },
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountEditBar(
                onSave: state.status == AccountStatus.ready && !saving
                    ? save
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.status == AccountStatus.loading)
                const Center(child: CircularProgressIndicator())
              else if (state.status == AccountStatus.failure)
                AccountEditFailure(messageKey: state.messageKey)
              else
                Expanded(
                  child: AccountEditFields(
                    first: first,
                    last: last,
                    display: display,
                    phoneNumber: state.account!.phoneNumber,
                    requiredError: requiredError,
                    onChanged: refresh,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

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
