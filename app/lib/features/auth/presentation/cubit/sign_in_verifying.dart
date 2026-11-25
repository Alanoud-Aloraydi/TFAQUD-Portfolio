import 'package:app/features/auth/domain/entities/sign_in_failures.dart';
import 'package:app/features/auth/presentation/cubit/request_is_closed.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_scope.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Checking the code the user typed.
mixin SignInVerifying on Cubit<SignInState>, SignInScope {
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

/// A changed copy of a [SignInState].
extension SignInStateCopy on SignInState {
  SignInState copyWith({
    String? phone,
    String? code,
    SignInStatus? status,
    String? errorKey,
    bool clearError = false,
    bool? showPhoneError,
    int? resendSeconds,
    String? verificationId,
    bool clearVerificationId = false,
    bool? needsProfile,
    CircleAppMode? appMode,
  }) {
    return SignInState(
      phone: phone ?? this.phone,
      code: code ?? this.code,
      status: status ?? this.status,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      showPhoneError: showPhoneError ?? this.showPhoneError,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      verificationId: clearVerificationId
          ? null
          : (verificationId ?? this.verificationId),
      needsProfile: needsProfile ?? this.needsProfile,
      appMode: appMode ?? this.appMode,
    );
  }
}
