import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_failures.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_loading.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Answering an invitation to manage a circle.
mixin InvitationAnswers
    on Cubit<InboxState>, InboxScope, InboxBusy, InboxLoading {
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
}
