import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/domain/usecases/profile_use_case.dart';
import 'package:app/features/account/presentation/cubit/account_loading.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_failures.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The account page (F05): the names, the phone number, the requests sent that
/// wait for the patient, changing the names, and deleting the account.
class AccountCubit extends Cubit<AccountState>
    with
        AccountScope,
        AccountLoading,
        AccountProfileSaving,
        AccountRequests,
        AccountDeleteRun,
        AccountDeleting {
  AccountCubit(this.circles, this.profile, this.auth, this.home)
    : super(const AccountState());

  @override
  final CirclesUseCase circles;
  @override
  final ProfileUseCase profile;
  @override
  final AuthUseCase auth;
  @override
  final HomeUseCase home;
}

/// Deleting the account, one question at a time.
mixin AccountDeleting on AccountScope, AccountDeleteRun {
  /// Asks the first question: "Delete your account?".
  void startDelete() {
    if (state.deleting) return;
    emit(
      state.copyWith(
        deletePrompt: DeletePrompt.confirm,
        deletion: const AccountDeletion(),
        clearMessages: true,
      ),
    );
  }

  /// The person answered no to a question: nothing is deleted.
  void cancelDelete() {
    emit(
      state.copyWith(
        deletePrompt: DeletePrompt.none,
        deletion: const AccountDeletion(),
      ),
    );
  }

  /// The person answered yes to the first question.
  Future<void> confirmDelete() => runDelete(const AccountDeletion());

  /// The person chose what happens to the circle they receive care in.
  Future<void> choosePatient(PatientChoice choice) =>
      runDelete(state.deletion.copyWith(patientChoice: choice));

  /// The person agreed to delete the circles they are the only manager of.
  Future<void> confirmLastManager() =>
      runDelete(state.deletion.copyWith(deleteLastManagedCircles: true));
}

/// Changing the names and the city on the account.
mixin AccountProfileSaving on AccountScope {
  /// Saves the three names, and [city] when it changed. Returns null when
  /// they were saved, and the key of the message to show otherwise, so the
  /// page that asked can stay open.
  Future<String?> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    String? city,
  }) async {
    final AccountSummary? current = state.account;
    final String first = firstName.trim();
    final String last = lastName.trim();
    final String display = displayName.trim();
    if (current == null || first.isEmpty || last.isEmpty || display.isEmpty) {
      return 'common.field_required';
    }
    // An unchanged city is not sent: it would set the zone of the circle
    // the account is the patient of again, over one chosen on its file.
    final String? newCity = city == current.city ? null : city;
    final result = await profile.saveProfile(
      firstName: first,
      lastName: last,
      displayName: display,
      city: newCity,
    );
    if (isClosed) return null;
    return result.when(
      (_) {
        emit(
          state.copyWith(
            account: AccountSummary(
              firstName: first,
              lastName: last,
              displayName: display,
              phoneNumber: current.phoneNumber,
              patientCircleId: current.patientCircleId,
              birthDate: current.birthDate,
              city: newCity ?? current.city,
              avatarCode: current.avatarCode,
            ),
            noticeKey: 'account.saved',
          ),
        );
        // The first letter of the display name is on the top bar of the home
        // screen, and the weather of «اليوم» follows the city: the home
        // screen loads again.
        home.notifyCirclesChanged();
        return null;
      },
      (Failure failure) {
        if (endsSession(failure)) emit(state.copyWith(sessionEnded: true));
        return failure.messageKey;
      },
    );
  }
}

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
