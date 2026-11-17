import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_scope.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// What the server's answer does to the page: a circle that was created
/// tells every home screen, and a refusal says why.
mixin CreateCircleResult on Cubit<CreateCircleState>, CreateCircleScope {
  bool finishCreate(
    Result<(CareCircleSummary, CircleAppMode), Failure> result,
  ) {
    return result.when(
      (data) {
        final (CareCircleSummary circle, CircleAppMode mode) = data;
        // Every open home screen loads the circles again and selects this one.
        home.notifyCirclesChanged(select: circle.id);
        emit(
          state.copyWith(
            status: CreateStatus.created,
            switchToSimplified: mode == CircleAppMode.simplified,
          ),
        );
        return true;
      },
      (failure) {
        // The first try may have been saved with its answer lost. Loading the
        // circles again shows it.
        if (failure is AlreadyHasCircleFailure) home.notifyCirclesChanged();
        emit(
          state.copyWith(
            status: CreateStatus.idle,
            errorKey: failure.messageKey,
            sessionEnded: endedSession(failure),
          ),
        );
        return false;
      },
    );
  }
}
