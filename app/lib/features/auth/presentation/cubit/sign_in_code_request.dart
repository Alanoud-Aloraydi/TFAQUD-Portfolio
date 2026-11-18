import 'package:app/features/auth/domain/failures/sign_in_failures.dart';
import 'package:app/features/auth/presentation/cubit/request_is_closed.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_countdown.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_scope.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One request for a code: the answer starts the wait before the next one,
/// and the answer of a request the user already left is dropped.
mixin SignInCodeRequest on Cubit<SignInState>, SignInScope, SignInCountdown {
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
}
