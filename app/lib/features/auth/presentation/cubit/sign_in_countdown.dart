import 'dart:async';

import 'package:app/features/auth/presentation/cubit/sign_in_scope.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The wait before a new code may be asked for, counted down on screen.
mixin SignInCountdown on Cubit<SignInState>, SignInScope {
  /// Starts the wait of [seconds] and counts it down once a second.
  void startCountdown(int seconds) {
    countdown?.cancel();
    waitSeconds = seconds;
    resendAt = clock().add(Duration(seconds: seconds));
    emit(state.copyWith(resendSeconds: seconds));
    countdown = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final int left = secondsLeft();
      if (left == 0) timer.cancel();
      emit(state.copyWith(resendSeconds: left));
    });
  }

  /// Whole seconds until [resendAt], rounded up and never more than the wait
  /// that was set (a phone clock moved back must not lengthen it).
  int secondsLeft() {
    final DateTime? end = resendAt;
    if (end == null) return 0;
    final int millis = end.difference(clock()).inMilliseconds;
    if (millis <= 0) return 0;
    final int seconds = (millis / 1000).ceil();
    return seconds > waitSeconds ? waitSeconds : seconds;
  }
}
