import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';

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
