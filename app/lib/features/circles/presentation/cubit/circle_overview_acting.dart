import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/circles/domain/entities/circle_failures.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// One change of the members at a time.
mixin CircleOverviewActing
    on Cubit<CircleOverviewState>, CircleOverviewScope, CircleOverviewLoading {
  /// A call while another is on its way (or before the circle is read)
  /// sends nothing and returns null; the page disables its buttons while
  /// [CircleOverviewState.acting]. After a success (when [reload]), and
  /// after a failure that means the tab is out of date, the circle is read
  /// again.
  Future<String?> act(
    Future<Result<void, Failure>> Function() call, {
    bool reload = true,
  }) async {
    if (state.acting || state.status != CircleOverviewStatus.ready) {
      return null;
    }
    emit(state.copyWith(acting: true));
    final Result<void, Failure> result = await call();
    if (isClosed) return null;
    emit(state.copyWith(acting: false));
    final Failure? failure = result.tryGetError();
    if ((failure == null && reload) || _tabIsStale(failure)) {
      await load();
    }
    return failure?.messageKey;
  }

  /// A failure that means the tab shows old members: the invitation or the
  /// member is gone already, or the person's access changed meanwhile.
  bool _tabIsStale(Failure? failure) =>
      failure is InvitationUnavailableFailure ||
      failure is LeaveDeletesCircleFailure ||
      failure is NotFoundFailure ||
      failure is ForbiddenFailure;
}
