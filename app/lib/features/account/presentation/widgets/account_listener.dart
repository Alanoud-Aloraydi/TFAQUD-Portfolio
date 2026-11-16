import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
