import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_code_request.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_scope.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates sign in actions and UI state.
class SignInCubit extends Cubit<SignInState>
    with
        SignInScope,
        SignInTyping,
        SignInCountdown,
        SignInCodeRequest,
        SignInRequesting,
        SignInVerifying {
  /// [clock] tells the time the resend wait is measured against; the tests
  /// give their own.
  SignInCubit(this.useCase, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now,
      super(const SignInState());

  @override
  final AuthUseCase useCase;

  @override
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
}

/// Asking the server for a code, the first time and again.
mixin SignInRequesting on Cubit<SignInState>, SignInCodeRequest {
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
}

/// What the user types on the two pages, and the way back to the number.
mixin SignInTyping on Cubit<SignInState>, SignInScope {
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
}
