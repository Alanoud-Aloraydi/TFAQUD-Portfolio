import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/presentation/cubit/inbox_busy.dart';
import 'package:app/features/circles/presentation/cubit/inbox_loading.dart';
import 'package:app/features/circles/presentation/cubit/inbox_scope.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
