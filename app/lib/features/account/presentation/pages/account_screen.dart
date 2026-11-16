import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_content.dart';
import 'package:app/features/account/presentation/widgets/account_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "حسابي": the person's names and phone number, the circles that wait for the
/// patient's approval, sign-out and deleting the account. Needs an
/// [AccountCubit] and an AuthCubit above it.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountCubit cubit = context.read<AccountCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: BlocConsumer<AccountCubit, AccountState>(
            listenWhen: accountShouldListen,
            listener: (BuildContext context, AccountState state) =>
                accountListen(context, cubit, state),
            builder: (BuildContext context, AccountState state) =>
                accountContent(context, cubit, state),
          ),
        ),
      ),
    );
  }
}
