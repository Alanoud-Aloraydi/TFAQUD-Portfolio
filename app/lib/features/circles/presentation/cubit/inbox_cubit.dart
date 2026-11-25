import 'dart:async';

import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_failures.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the requests and invitations that wait for an answer. The bell of the
/// home screen keeps one ([followCircleChanges] on) and the notifications page
/// has its own.
class InboxCubit extends Cubit<InboxState> {
  InboxCubit(this.circles, this.home, {this.followCircleChanges = false})
    : super(const InboxState()) {
    if (followCircleChanges) {
      _changes = home.changes.listen((_) => load());
    }
  }

  final CirclesUseCase circles;

  final HomeUseCase home;

  /// Load again whenever the circles of the account change (a circle was
  /// created from a request, an invitation was accepted). Only the cubit of
  /// the bell does this.
  final bool followCircleChanges;

  StreamSubscription<String?>? _changes;

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }

  /// Counts the readings, so a slower one cannot overwrite a newer answer.
  int revision = 0;

  /// Whether the session itself ended, which the page answers by leaving.
  bool endedSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;

  /// Marks [id] busy and clears the message of the answer before it.
  void startAnswer(String id) => emit(
    state.copyWith(busyIds: <String>{...state.busyIds, id}, clearError: true),
  );

  /// The busy rows without [id].
  Set<String> withoutBusy(String id) => <String>{...state.busyIds}..remove(id);

  /// A refused answer: the row is free again and says why.
  void refuseAnswer(String id, Failure failure) => emit(
    state.copyWith(
      busyIds: withoutBusy(id),
      errorKey: failure.messageKey,
      sessionEnded: endedSession(failure),
    ),
  );

  /// Clears the message of the last failed answer, once the page showed it.
  void errorShown() => emit(state.copyWith(clearError: true));

  /// Reads the inbox. The first read shows the loading state; a later read
  /// keeps the list on screen until the new one arrives, and a failure of a
  /// later read keeps the list.
  Future<void> load() async {
    final int revision = ++this.revision;
    if (state.status != InboxStatus.ready) {
      emit(state.copyWith(status: InboxStatus.loading));
    }
    final result = await circles.getInbox();
    if (isClosed || revision != this.revision) return;
    result.when(
      (CircleInbox inbox) => emit(
        InboxState(
          status: InboxStatus.ready,
          inbox: inbox,
          errorKey: state.errorKey,
          busyIds: state.busyIds,
        ),
      ),
      (Failure failure) {
        if (state.status == InboxStatus.ready) {
          if (endedSession(failure)) {
            emit(state.copyWith(sessionEnded: true));
          }
          return;
        }
        emit(
          InboxState(
            status: InboxStatus.failure,
            messageKey: failure.messageKey,
            sessionEnded: endedSession(failure),
          ),
        );
      },
    );
  }

  /// Accepts or declines an invitation. Returns true when the server saved
  /// the answer. An accepted invitation adds a circle, so the home screen
  /// loads the circles again and selects it.
  Future<bool> respondToInvitation(String id, {required bool accept}) async {
    if (state.busyIds.contains(id)) return false;
    startAnswer(id);
    final result = await circles.respondToInvitation(id, accept: accept);
    if (isClosed) return false;
    return result.when(
      (String? circleId) {
        final CircleInbox now = state.inbox;
        emit(
          state.copyWith(
            busyIds: withoutBusy(id),
            inbox: CircleInbox(
              sent: now.sent,
              received: now.received,
              invitations: <ReceivedInvitation>[
                for (final ReceivedInvitation invitation in now.invitations)
                  if (invitation.id != id) invitation,
              ],
              previous: now.previous,
            ),
          ),
        );
        if (circleId != null) home.notifyCirclesChanged(select: circleId);
        unawaited(load());
        return true;
      },
      (Failure failure) {
        refuseAnswer(id, failure);
        // The invitation may be gone already: read the list again.
        if (failure is RequestUnavailableFailure) unawaited(load());
        return false;
      },
    );
  }

  /// Returns true when the server saved the cancellation.
  Future<bool> cancelRequest(String id) async {
    if (state.busyIds.contains(id)) return false;
    startAnswer(id);
    final result = await circles.cancelRequest(id);
    if (isClosed) return false;
    return result.when(
      (_) {
        emit(state.copyWith(busyIds: withoutBusy(id)));
        unawaited(load());
        return true;
      },
      (Failure failure) {
        refuseAnswer(id, failure);
        if (failure is RequestUnavailableFailure) unawaited(load());
        return false;
      },
    );
  }
}
