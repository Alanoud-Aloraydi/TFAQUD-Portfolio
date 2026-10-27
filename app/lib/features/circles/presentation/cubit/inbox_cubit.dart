import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the requests and invitations that wait for an answer. The bell of the
/// home screen keeps one ([followCircleChanges] on) and the notifications page
/// has its own.
class InboxCubit extends Cubit<InboxState> {
  InboxCubit(
    this._circles,
    this._home, {
    this.followCircleChanges = false,
  }) : super(const InboxState()) {
    if (followCircleChanges) {
      _changes = _home.changes.listen((_) => load());
    }
  }

  final CirclesUseCase _circles;
  final HomeUseCase _home;

  /// Load again whenever the circles of the account change (a circle was
  /// created from a request, an invitation was accepted). Only the cubit of
  /// the bell does this.
  final bool followCircleChanges;

  StreamSubscription<String?>? _changes;
  int _revision = 0;

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }

  /// Reads the inbox. The first read shows the loading state; a later read
  /// keeps the list on screen until the new one arrives, and a failure of a
  /// later read keeps the list.
  Future<void> load() async {
    final int revision = ++_revision;
    if (state.status != InboxStatus.ready) {
      emit(state.copyWith(status: InboxStatus.loading));
    }
    final result = await _circles.getInbox();
    if (isClosed || revision != _revision) return;
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
          if (_ended(failure)) emit(state.copyWith(sessionEnded: true));
          return;
        }
        emit(
          InboxState(
            status: InboxStatus.failure,
            messageKey: failure.messageKey,
            sessionEnded: _ended(failure),
          ),
        );
      },
    );
  }

  /// Accepts or declines an invitation to manage a circle. Returns true when
  /// the server saved the answer. An accepted invitation adds a circle, so the
  /// home screen loads the circles again and selects it.
  Future<bool> respondToInvitation(String id, {required bool accept}) async {
    if (state.busyIds.contains(id)) return false;
    emit(state.copyWith(busyIds: <String>{...state.busyIds, id}, clearError: true));
    final result = await _circles.respondToInvitation(id, accept: accept);
    if (isClosed) return false;
    final Set<String> busy = <String>{...state.busyIds}..remove(id);
    return result.when(
      (String? circleId) {
        final CircleInbox now = state.inbox;
        emit(
          state.copyWith(
            busyIds: busy,
            inbox: CircleInbox(
              sent: now.sent,
              received: now.received,
              invitations: <ReceivedInvitation>[
                for (final ReceivedInvitation invitation in now.invitations)
                  if (invitation.id != id) invitation,
              ],
            ),
          ),
        );
        if (circleId != null) _home.notifyCirclesChanged(select: circleId);
        unawaited(load());
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
        // The invitation may be gone already: read the list again.
        if (failure is RequestUnavailableFailure) unawaited(load());
        return false;
      },
    );
  }

  /// Cancels a request, from either side. Returns true when the server saved
  /// the cancellation.
  Future<bool> cancelRequest(String id) async {
    if (state.busyIds.contains(id)) return false;
    emit(state.copyWith(busyIds: <String>{...state.busyIds, id}, clearError: true));
    final result = await _circles.cancelRequest(id);
    if (isClosed) return false;
    final Set<String> busy = <String>{...state.busyIds}..remove(id);
    return result.when(
      (_) {
        emit(state.copyWith(busyIds: busy));
        unawaited(load());
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
        if (failure is RequestUnavailableFailure) unawaited(load());
        return false;
      },
    );
  }

  /// Clears the message of the last failed answer, once the page showed it.
  void errorShown() => emit(state.copyWith(clearError: true));

  bool _ended(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
