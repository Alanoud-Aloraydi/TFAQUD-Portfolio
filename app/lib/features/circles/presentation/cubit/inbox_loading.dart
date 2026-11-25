import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reading what waits for an answer.
mixin InboxLoading on Cubit<InboxState>, InboxScope {
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
}
