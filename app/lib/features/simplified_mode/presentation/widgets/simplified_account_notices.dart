import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_delete_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// A change in «حسابي» the patient must be told about: the session
/// ending, a sign-out, a failure, or the next question about deleting.
bool simplifiedAccountNotable(AccountState before, AccountState after) =>
    (after.sessionEnded && !before.sessionEnded) ||
    (after.signedOut && !before.signedOut) ||
    (after.errorKey != null && after.errorKey != before.errorKey) ||
    (after.deletePrompt != before.deletePrompt &&
        after.deletePrompt != DeletePrompt.none);

/// Leaves for the sign-in screen, shows a failure once, and asks the next
/// question of deleting.
void simplifiedAccountNotice(BuildContext context, AccountState state) {
  final AccountCubit cubit = context.read<AccountCubit>();
  if (state.sessionEnded || state.signedOut) {
    context.go(Routes.auth);
    return;
  }
  if (state.errorKey case final String key) {
    AppToast.show(
      context,
      key,
      kind: state.errorKey != null ? ToastKind.error : ToastKind.success,
    );
    cubit.messagesShown();
  }
  if (state.deletePrompt != DeletePrompt.none) {
    answerDeletePrompt(
      context,
      cubit,
      state.deletePrompt,
      confirm: confirmSimplifiedDelete,
    );
  }
}
