import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/presentation/cubit/account_loading.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_failures.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';

/// Cancelling the requests this account sent, and clearing what the page
/// showed.
mixin AccountRequests on AccountScope, AccountLoading {
  /// Cancels a request this account sent. Returns true when it was canceled.
  Future<bool> cancelRequest(String id) async {
    if (state.busyIds.contains(id)) return false;
    emit(
      state.copyWith(
        busyIds: <String>{...state.busyIds, id},
        clearMessages: true,
      ),
    );
    final result = await circles.cancelRequest(id);
    if (isClosed) return false;
    final Set<String> busy = <String>{...state.busyIds}..remove(id);
    return result.when(
      (_) {
        emit(
          state.copyWith(
            busyIds: busy,
            sent: <SentCircleRequest>[
              for (final SentCircleRequest sent in state.sent)
                if (sent.id != id) sent,
            ],
            noticeKey: 'account.request_canceled',
          ),
        );
        return true;
      },
      (Failure failure) {
        emit(
          state.copyWith(
            busyIds: busy,
            errorKey: failure.messageKey,
            sessionEnded: endsSession(failure),
          ),
        );
        // The request may be gone already: read the list again.
        if (failure is RequestUnavailableFailure) load();
        return false;
      },
    );
  }

  /// Clears the failure and the notice once the page showed them, so that the
  /// same message can be shown again later.
  void messagesShown() => emit(state.copyWith(clearMessages: true));
}

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
