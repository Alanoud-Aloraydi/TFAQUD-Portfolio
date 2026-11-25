import 'dart:async';

import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the sign-in pages are bound to, shared by everything they do.
mixin SignInScope on Cubit<SignInState> {
  AuthUseCase get useCase;

  /// Tells the time the resend wait is measured against; the tests give
  /// their own.
  DateTime Function() get clock;

  Timer? countdown;

  /// When the wait before the next code ends, and how long it was. The
  /// seconds on screen are always counted from [resendAt], so a phone that
  /// slept (the timer stops in the background) shows the true wait.
  DateTime? resendAt;
  int waitSeconds = 0;

  /// Counts the code requests, so the answer of a request the user already
  /// left (by going back to change the number) is dropped.
  int attempt = 0;
}
