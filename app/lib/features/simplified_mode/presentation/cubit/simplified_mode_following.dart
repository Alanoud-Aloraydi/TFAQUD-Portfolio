import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_scope.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Keeping the state in step with what moves on its own: the clock and the
/// tasks put off.
mixin SimplifiedModeFollowing
    on Cubit<SimplifiedModeState>, SimplifiedModeScope {
  /// Moves the state's instant to now.
  void followClock() {
    if (isClosed) return;
    emit(state.copyWith(now: clock()));
  }

  /// Takes the tasks put off, as the use case holds them now.
  void followSnoozes() {
    if (isClosed) return;
    emit(state.copyWith(snoozes: useCase.snoozes.value));
  }
}
