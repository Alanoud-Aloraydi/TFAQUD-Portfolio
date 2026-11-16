import 'package:app/features/circles/presentation/cubit/account_load.dart';
import 'package:app/features/circles/presentation/cubit/circle_flow.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_scope.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reading the account the circle is created from.
mixin CreateCircleAccount on Cubit<CreateCircleState>, CreateCircleScope {
  /// Loads the account: its name, whether it already has a circle of its own
  /// care, and the birth date and city onboarding saved. The page works
  /// without it (it then asks for the birth date and city), so a failure
  /// shows a message and a retry; the server still refuses a second circle.
  /// Does nothing for [CircleFlow.patient], whose patient is someone else.
  Future<void> loadAccount() async {
    if (flow == CircleFlow.patient) return;
    emit(state.copyWith(accountLoad: AccountLoad.loading));
    final result = await circles.getAccount();
    if (isClosed) return;
    result.when(
      (account) {
        emit(state.copyWith(account: account, accountLoad: AccountLoad.loaded));
        // The home screen may not show that circle yet; it loads again.
        if (account.hasOwnCircle) home.notifyCirclesChanged();
      },
      (failure) => emit(
        state.copyWith(
          accountLoad: AccountLoad.failed,
          sessionEnded: endedSession(failure),
        ),
      ),
    );
  }
}
