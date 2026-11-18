import 'package:app/features/account/presentation/cubit/account_state.dart';

/// What makes two [AccountState]s equal: every field, in the order the
/// class declares them.
List<Object?> accountStateProps(AccountState state) => <Object?>[
  state.status,
  state.account,
  state.circles,
  state.sent,
  state.messageKey,
  state.errorKey,
  state.noticeKey,
  state.busyIds,
  state.deleting,
  state.deletePrompt,
  state.deletion,
  state.signedOut,
  state.sessionEnded,
];
