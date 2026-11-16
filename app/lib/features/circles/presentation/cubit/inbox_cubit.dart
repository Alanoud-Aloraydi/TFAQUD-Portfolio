import 'dart:async';

import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_busy.dart';
import 'package:app/features/circles/presentation/cubit/inbox_loading.dart';
import 'package:app/features/circles/presentation/cubit/inbox_scope.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/cubit/invitation_answers.dart';
import 'package:app/features/circles/presentation/cubit/request_cancelling.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
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
