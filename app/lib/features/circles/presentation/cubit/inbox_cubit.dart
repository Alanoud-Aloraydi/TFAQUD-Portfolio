import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_failures.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_loading.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/cubit/invitation_answers.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the requests and invitations that wait for an answer. The bell of the
/// home screen keeps one ([followCircleChanges] on) and the notifications page
/// has its own.
class InboxCubit extends Cubit<InboxState>
    with
        InboxScope,
        InboxBusy,
        InboxLoading,
        InvitationAnswers,
        RequestCancelling {
  InboxCubit(this.circles, this.home, {this.followCircleChanges = false})
    : super(const InboxState()) {
    if (followCircleChanges) {
      _changes = home.changes.listen((_) => load());
    }
  }

  @override
  final CirclesUseCase circles;

  @override
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
}

/// Taking back a request, from either side.
mixin RequestCancelling
    on Cubit<InboxState>, InboxScope, InboxBusy, InboxLoading {
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

/// One row of the inbox at a time: while its own answer is on its way the
/// row is busy, so its buttons are quiet and a second tap does nothing.
mixin InboxBusy on Cubit<InboxState>, InboxScope {
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
}
