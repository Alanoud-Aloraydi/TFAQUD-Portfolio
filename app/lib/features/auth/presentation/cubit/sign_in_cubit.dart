import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/failures/sign_in_failures.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._useCase) : super(const SignInState());

  final AuthUseCase _useCase;
  Timer? _timer;

  /// Digits in the code. The SMS template of Authentica sends six.
  static const int codeLength = 6;

  /// Seconds the user waits before asking for a new code (from the design).
  static const int resendCooldownSeconds = 45;

  static final RegExp _phonePattern = RegExp(r'^5[0-9]{8}$');

  /// Saudi mobile number: nine digits, the first one is 5, no leading zero.
  bool get isPhoneValid => _phonePattern.hasMatch(state.phone);

  String get fullPhone => '+966${state.phone}';

  void phoneChanged(String digits) {
    emit(
      state.copyWith(phone: digits, showPhoneError: false, clearError: true),
    );
  }

  void codeChanged(String digits) {
    emit(state.copyWith(code: digits, clearError: true));
  }

  /// Sends the code from the phone page. This always starts a new request, so
  /// an earlier request is never reused. Returns true when the code was sent,
  /// so the page can move on.
  Future<bool> sendCode() async {
    if (state.status == SignInStatus.sendingCode) return false;
    if (!isPhoneValid) {
      emit(state.copyWith(showPhoneError: true, clearError: true));
      return false;
    }
    return _requestCode(verificationId: null);
  }

  /// Asks for a new code on the code page. Does nothing while the countdown
  /// runs. The SMS belongs to the same request, so the server keeps counting
  /// the wrong tries already used. If the server closed the request there is
  /// no id any more, and a new request starts.
  Future<bool> resendCode() async {
    if (state.resendSeconds > 0) return false;
    if (state.status == SignInStatus.sendingCode) return false;
    return _requestCode(verificationId: state.verificationId);
  }

  Future<bool> _requestCode({required String? verificationId}) async {
    emit(
      state.copyWith(
        status: SignInStatus.sendingCode,
        code: '',
        showPhoneError: false,
        clearError: true,
      ),
    );
    final result = await _useCase.requestCode(
      fullPhone,
      verificationId: verificationId,
    );
    if (isClosed) return false;
    return result.when(
      (id) {
        _startCountdown();
        emit(state.copyWith(status: SignInStatus.codeSent, verificationId: id));
        return true;
      },
      (failure) {
        emit(
          state.copyWith(
            status: SignInStatus.idle,
            errorKey: failure.messageKey,
            clearVerificationId: _requestIsClosed(failure),
          ),
        );
        return false;
      },
    );
  }

  /// Checks the code. Returns true when it is correct.
  Future<bool> verify() async {
    if (state.status == SignInStatus.verifying) return false;
    if (state.code.length != codeLength) {
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
    final result = await _useCase.verifyCode(
      verificationId: verificationId,
      code: state.code,
    );
    if (isClosed) return false;
    return result.when(
      (signIn) {
        _timer?.cancel();
        emit(
          state.copyWith(
            status: SignInStatus.verified,
            needsProfile: signIn.needsProfile,
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
            clearVerificationId: _requestIsClosed(failure),
          ),
        );
        return false;
      },
    );
  }

  /// The user leaves the code page to change the number. The request belonged
  /// to the old number, so it is forgotten.
  void backToPhone() {
    _timer?.cancel();
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

  /// True when the server will accept nothing more on this request: the three
  /// wrong tries are used, or the request is unknown or already finished.
  /// Asking for a code again must then start a new request.
  bool _requestIsClosed(Failure failure) =>
      failure is TooManyAttemptsFailure || failure is StartAgainFailure;

  void _startCountdown() {
    _timer?.cancel();
    emit(state.copyWith(resendSeconds: resendCooldownSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final int left = state.resendSeconds - 1;
      if (left <= 0) timer.cancel();
      emit(state.copyWith(resendSeconds: left < 0 ? 0 : left));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
