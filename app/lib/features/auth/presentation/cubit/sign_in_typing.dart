import 'package:app/features/auth/presentation/cubit/sign_in_scope.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
