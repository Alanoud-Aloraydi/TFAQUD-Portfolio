import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/presentation/cubit/inbox_scope.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
