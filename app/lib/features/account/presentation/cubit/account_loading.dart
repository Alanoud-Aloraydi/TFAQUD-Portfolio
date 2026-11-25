import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/domain/usecases/profile_use_case.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Reading the account and the requests it sent.
mixin AccountLoading on AccountScope {
  /// Reads the account and the requests this account sent. The account is
  /// needed; when only the requests fail the page still shows the account.
  /// A failed first read is [AccountStatus.failure] (the page offers a
  /// retry); a failed refresh keeps the page and sets [AccountState.errorKey].
  Future<void> load() async {
    final int current = ++revision;
    if (state.status != AccountStatus.ready) {
      emit(state.copyWith(status: AccountStatus.loading, clearMessages: true));
    }
    final List<Object> answers = await Future.wait<Object>(<Future<Object>>[
      circles.getAccount(),
      circles.getInbox(),
      home.getHome(),
    ]);
    if (isClosed || current != revision) return;
    final account = answers[0] as Result<AccountSummary, Failure>;
    final inbox = answers[1] as Result<CircleInbox, Failure>;
    final read = answers[2] as Result<HomeEntity, Failure>;
    account.when(
      (AccountSummary summary) => emit(
        // copyWith keeps a delete flow that is running, and the messages.
        state.copyWith(
          status: AccountStatus.ready,
          account: summary,
          circles: read.when(
            (HomeEntity entity) => entity.circles,
            (Failure _) => state.circles,
          ),
          sent: inbox.when(
            (CircleInbox sent) => waitingRequests(sent),
            (Failure _) => state.sent,
          ),
        ),
      ),
      (Failure failure) {
        if (state.status == AccountStatus.ready) {
          // A refresh that fails keeps the page and says so once.
          emit(
            state.copyWith(
              errorKey: failure.messageKey,
              sessionEnded: endsSession(failure),
            ),
          );
          return;
        }
        emit(
          AccountState(
            status: AccountStatus.failure,
            messageKey: failure.messageKey,
            sessionEnded: endsSession(failure),
          ),
        );
      },
    );
  }
}

/// The sent requests that wait for the patient. A declined one is not a
/// circle waiting for approval; the notifications page tells about it.
List<SentCircleRequest> waitingRequests(CircleInbox inbox) =>
    <SentCircleRequest>[
      for (final SentCircleRequest sent in inbox.sent)
        if (sent.status == CircleRequestStatus.pending ||
            sent.status == CircleRequestStatus.accepted)
          sent,
    ];

/// What every part of the account cubit works on: the use cases it asks, the
/// counter that drops an older reading, and how a failure ends the session.
mixin AccountScope on Cubit<AccountState> {
  CirclesUseCase get circles;
  ProfileUseCase get profile;
  AuthUseCase get auth;
  HomeUseCase get home;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// Whether the failure means the sign-in is no longer valid.
  bool endsSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
