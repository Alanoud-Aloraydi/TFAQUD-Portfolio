import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/presentation/cubit/account_scope.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';

/// Sending the deletion of the account, and what the answer means.
mixin AccountDeleteRun on AccountScope {
  /// Asks the server to delete the account with the choices made so far, and
  /// says where that got to.
  Future<void> runDelete(AccountDeletion deletion) async {
    if (state.deleting) return;
    emit(
      state.copyWith(
        deleting: true,
        deletion: deletion,
        deletePrompt: DeletePrompt.none,
        clearMessages: true,
      ),
    );
    final result = await circles.deleteAccount(deletion);
    if (isClosed) return;
    if (result.isSuccess()) {
      // Every sign-in of the account ended on the server. This one is ended on
      // the phone too: the tokens are removed.
      await auth.signOut();
      if (isClosed) return;
      emit(state.copyWith(deleting: false, signedOut: true));
      return;
    }
    final Failure failure = result.tryGetError()!;
    emit(
      state.copyWith(
        deleting: false,
        deletePrompt: switch (failure) {
          PatientChoiceRequiredFailure() => DeletePrompt.patientChoice,
          LastManagerFailure() => DeletePrompt.lastManager,
          _ => DeletePrompt.none,
        },
        errorKey:
            failure is PatientChoiceRequiredFailure ||
                failure is LastManagerFailure
            ? null
            : failure.messageKey,
        sessionEnded: endsSession(failure),
      ),
    );
  }
}
