import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_content.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

/// The state changes «حسابي» answers with more than a repaint: the end of the
/// sign-in, a message to show once, and the next question about deleting.
bool accountShouldListen(AccountState before, AccountState after) =>
    (after.sessionEnded && !before.sessionEnded) ||
    (after.signedOut && !before.signedOut) ||
    (after.errorKey != null && after.errorKey != before.errorKey) ||
    (after.noticeKey != null && after.noticeKey != before.noticeKey) ||
    (after.deletePrompt != before.deletePrompt &&
        after.deletePrompt != DeletePrompt.none);

/// Goes to sign-in once the session is over, shows the one message the state
/// carries, and asks the next question of the delete flow.
void accountListen(
  BuildContext context,
  AccountCubit cubit,
  AccountState state,
) {
  if (state.sessionEnded || state.signedOut) {
    context.go(Routes.auth);
    return;
  }
  final String? key = state.errorKey ?? state.noticeKey;
  if (key != null) {
    AppToast.show(
      context,
      key,
      kind: state.errorKey != null ? ToastKind.error : ToastKind.success,
    );
    cubit.messagesShown();
  }
  if (state.deletePrompt != DeletePrompt.none) {
    answerDeletePrompt(context, cubit, state.deletePrompt);
  }
}
