import 'package:app/app/router/routers.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_rows.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_text.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «حسابي»: the patient's name and number, the text size and reading,
/// the calendar copy of appointments, the medical file, signing out and
/// deleting the account. Needs an [AccountCubit] and an [AuthCubit].
class SimplifiedAccountScreen extends StatelessWidget {
  const SimplifiedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? circleId = context.select<SimplifiedModeCubit, String?>(
      (cubit) => cubit.state.day?.circleId,
    );
    return BlocListener<AccountCubit, AccountState>(
      listenWhen: simplifiedAccountNotable,
      listener: simplifiedAccountNotice,
      child: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) => SimplifiedPage(
          title: context.tr('simplified_mode.account_title'),
          children: simplifiedAccountRows(context, state, circleId),
        ),
      ),
    );
  }
}

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

/// The first question of deleting, asked as a big sheet.
Future<bool?> confirmSimplifiedDelete(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    backgroundColor: SimplifiedColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
        child: simplifiedDeleteSheetBody(sheetContext),
      ),
    ),
  );
}
