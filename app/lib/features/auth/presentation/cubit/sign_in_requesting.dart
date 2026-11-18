import 'package:app/features/auth/presentation/cubit/sign_in_code_request.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
