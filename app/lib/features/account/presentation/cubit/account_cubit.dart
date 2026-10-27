import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// The account page (F05): the names, the phone number, the requests sent that
/// wait for the patient, changing the names, and deleting the account.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._circles, this._onboarding, this._auth, this._home)
    : super(const AccountState());

  final CirclesUseCase _circles;
  final OnboardingUseCase _onboarding;
  final AuthUseCase _auth;
  final HomeUseCase _home;

  /// The longest names the API accepts (docs/api-contracts.md, section 5).
  static const int maxNameLength = 50;
  static const int maxDisplayNameLength = 30;

  int _revision = 0;

  /// Reads the account and the requests this account sent. The account is
  /// needed; when only the requests fail the page still shows the account.
  Future<void> load() async {
    final int revision = ++_revision;
    if (state.status != AccountStatus.ready) {
      emit(state.copyWith(status: AccountStatus.loading, clearMessages: true));
    }
    final List<Object> answers = await Future.wait<Object>(<Future<Object>>[
      _circles.getAccount(),
      _circles.getInbox(),
    ]);
    if (isClosed || revision != _revision) return;
    final account = answers[0] as Result<AccountSummary, Failure>;
    final inbox = answers[1] as Result<CircleInbox, Failure>;
    account.when(
      (AccountSummary summary) => emit(
        AccountState(
          status: AccountStatus.ready,
          account: summary,
          sent: inbox.when(
            (CircleInbox read) => _waiting(read),
            (Failure _) => state.sent,
          ),
          errorKey: state.errorKey,
          noticeKey: state.noticeKey,
          busyIds: state.busyIds,
        ),
      ),
      (Failure failure) {
        if (state.status == AccountStatus.ready) {
          if (_ended(failure)) emit(state.copyWith(sessionEnded: true));
          return;
        }
        emit(
          AccountState(
            status: AccountStatus.failure,
            messageKey: failure.messageKey,
            sessionEnded: _ended(failure),
          ),
        );
      },
    );
  }

  /// The sent requests that wait for the patient. A declined one is not a
  /// circle waiting for approval; the notifications page tells about it.
  List<SentCircleRequest> _waiting(CircleInbox inbox) => <SentCircleRequest>[
    for (final SentCircleRequest sent in inbox.sent)
      if (sent.status == CircleRequestStatus.pending ||
          sent.status == CircleRequestStatus.accepted)
        sent,
  ];

  /// Saves the three names. Returns null when they were saved, and the key of
  /// the message to show otherwise, so the sheet that asked can stay open.
  Future<String?> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  }) async {
    final AccountSummary? current = state.account;
    final String first = firstName.trim();
    final String last = lastName.trim();
    final String display = displayName.trim();
    if (current == null || first.isEmpty || last.isEmpty || display.isEmpty) {
      return 'circles.field_required';
    }
    final result = await _onboarding.saveProfile(
      firstName: first,
      lastName: last,
      displayName: display,
    );
    if (isClosed) return null;
    return result.when(
      (bool _) {
        emit(
          state.copyWith(
            account: AccountSummary(
              firstName: first,
              lastName: last,
              displayName: display,
              phoneNumber: current.phoneNumber,
              patientCircleId: current.patientCircleId,
            ),
            noticeKey: 'account.saved',
          ),
        );
        // The first letter of the display name is on the top bar of the home
        // screen, which loads again.
        _home.notifyCirclesChanged();
        return null;
      },
      (Failure failure) {
        if (_ended(failure)) emit(state.copyWith(sessionEnded: true));
        return failure.messageKey;
      },
    );
  }

  /// Cancels a request this account sent. Returns true when it was canceled.
  Future<bool> cancelRequest(String id) async {
    if (state.busyIds.contains(id)) return false;
    emit(
      state.copyWith(
        busyIds: <String>{...state.busyIds, id},
        clearMessages: true,
      ),
    );
    final result = await _circles.cancelRequest(id);
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
            sessionEnded: _ended(failure),
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

  // ---- deleting the account ------------------------------------------------

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
  Future<void> confirmDelete() => _delete(const AccountDeletion());

  /// The person chose what happens to the circle they receive care in.
  Future<void> choosePatient(PatientChoice choice) =>
      _delete(state.deletion.copyWith(patientChoice: choice));

  /// The person agreed to delete the circles they are the only manager of.
  Future<void> confirmLastManager() =>
      _delete(state.deletion.copyWith(deleteLastManagedCircles: true));

  Future<void> _delete(AccountDeletion deletion) async {
    if (state.deleting) return;
    emit(
      state.copyWith(
        deleting: true,
        deletion: deletion,
        deletePrompt: DeletePrompt.none,
        clearMessages: true,
      ),
    );
    final result = await _circles.deleteAccount(deletion);
    if (isClosed) return;
    if (result.isSuccess()) {
      // Every sign-in of the account ended on the server. This one is ended on
      // the phone too: the tokens are removed.
      await _auth.signOut();
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
        sessionEnded: _ended(failure),
      ),
    );
  }

  bool _ended(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
