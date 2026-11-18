import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/presentation/cubit/account_scope.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/cubit/account_waiting.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
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
