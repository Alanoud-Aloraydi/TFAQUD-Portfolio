import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/entities/sign_in_failures.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates sign in actions and UI state.
class SignInCubit extends Cubit<SignInState> {
  /// [clock] tells the time the resend wait is measured against; the tests
  /// give their own.
  SignInCubit(this.useCase, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now,
      super(const SignInState());

  final AuthUseCase useCase;

  final DateTime Function() clock;

  /// Digits in the code. The SMS template of Authentica sends six.
  static const int codeLength = 6;

  /// Seconds the user waits before asking for a new code when the server
  /// does not say (it normally does: 30 s, then longer after each code).
  static const int resendCooldownSeconds = 45;

  @override
  Future<void> close() {
    countdown?.cancel();
    return super.close();
  }

  Timer? countdown;

  /// When the wait before the next code ends, and how long it was. The
  /// seconds on screen are always counted from [resendAt], so a phone that
  /// slept (the timer stops in the background) shows the true wait.
  DateTime? resendAt;
  int waitSeconds = 0;

  /// Counts the code requests, so the answer of a request the user already
  /// left (by going back to change the number) is dropped.
  int attempt = 0;

  /// Stores the digits of the phone page.
  void phoneChanged(String digits) {
    emit(
      state.copyWith(phone: digits, showPhoneError: false, clearError: true),
    );
  }

  /// Stores the digits of the code page.
  void codeChanged(String digits) {
    emit(state.copyWith(code: digits, clearError: true));
  }

  /// The user leaves the code page to change the number. The request belonged
  /// to the old number, so it is forgotten, and so is the answer of a code
  /// still being sent.
  void backToPhone() {
    countdown?.cancel();
    attempt++;
    emit(
      state.copyWith(
        status: SignInStatus.idle,
        code: '',
        resendSeconds: 0,
        clearError: true,
        clearVerificationId: true,
      ),
    );
  }

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

  Future<bool> requestCode({required String? verificationId}) async {
    final int current = ++attempt;
    emit(
      state.copyWith(
        status: SignInStatus.sendingCode,
        code: '',
        showPhoneError: false,
        clearError: true,
      ),
    );
    final result = await useCase.requestCode(
      state.fullPhone,
      verificationId: verificationId,
    );
    if (isClosed || current != attempt) return false;
    return result.when(
      (sent) {
        // The server says when the next code may go; the wait grows with
        // each code.
        startCountdown(
          sent.resendAfterSeconds > 0
              ? sent.resendAfterSeconds
              : SignInCubit.resendCooldownSeconds,
        );
        emit(
          state.copyWith(
            status: SignInStatus.codeSent,
            verificationId: sent.verificationId,
          ),
        );
        return true;
      },
      (failure) {
        emit(
          state.copyWith(
            status: SignInStatus.idle,
            errorKey: failure.messageKey,
            clearVerificationId: requestIsClosed(failure),
          ),
        );
        // Too soon after the last code: the countdown shows how long.
        if (failure is ResendWaitFailure) startCountdown(failure.seconds);
        return false;
      },
    );
  }

  /// Sends the code from the phone page. This always starts a new request, so
  /// an earlier request is never reused. Returns true when the code was sent,
  /// so the page can move on.
  Future<bool> sendCode() async {
    if (state.busy) return false;
    if (!state.phoneValid) {
      emit(state.copyWith(showPhoneError: true, clearError: true));
      return false;
    }
    return requestCode(verificationId: null);
  }

  /// Asks for a new code on the code page. Does nothing while the countdown
  /// runs. The SMS belongs to the same request, so the server keeps counting
  /// the wrong tries already used. If the server closed the request there is
  /// no id any more, and a new request starts.
  Future<bool> resendCode() async {
    if (state.resendSeconds > 0 || state.busy) return false;
    return requestCode(verificationId: state.verificationId);
  }

  /// Checks the code. Returns true when it is correct; the state is then
  /// [SignInStatus.verified] and the page moves on.
  Future<bool> verify() async {
    if (state.busy) return false;
    if (state.code.length != SignInCubit.codeLength) {
      emit(state.copyWith(errorKey: 'auth.code_incomplete'));
      return false;
    }
    final String? verificationId = state.verificationId;
    if (verificationId == null) {
      // The server closed the request. Nothing to check the code against.
      emit(state.copyWith(errorKey: const StartAgainFailure().messageKey));
      return false;
    }
    emit(state.copyWith(status: SignInStatus.verifying, clearError: true));
    final result = await useCase.verifyCode(
      verificationId: verificationId,
      code: state.code,
    );
    if (isClosed) return false;
    return result.when(
      (signIn) {
        countdown?.cancel();
        emit(
          state.copyWith(
            status: SignInStatus.verified,
            needsProfile: signIn.needsProfile,
            appMode: signIn.appMode,
          ),
        );
        return true;
      },
      (failure) {
        // The boxes are cleared so the user can type the code again.
        emit(
          state.copyWith(
            status: SignInStatus.codeSent,
            code: '',
            errorKey: failure.messageKey,
            clearVerificationId: requestIsClosed(failure),
          ),
        );
        return false;
      },
    );
  }
}

/// True when the server will accept nothing more on this request: the three
/// wrong tries are used, or the request is unknown or already finished.
/// Asking for a code again must then start a new request.
bool requestIsClosed(Failure failure) =>
    failure is TooManyAttemptsFailure || failure is StartAgainFailure;
