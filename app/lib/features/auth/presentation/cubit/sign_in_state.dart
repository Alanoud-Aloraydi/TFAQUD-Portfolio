import 'package:equatable/equatable.dart';

enum SignInStatus { idle, sendingCode, codeSent, verifying, verified }

/// State of the sign-in pages (phone number, then code). One cubit serves both
/// pages, so the code page knows the phone number.
class SignInState extends Equatable {
  const SignInState({
    this.phone = '',
    this.code = '',
    this.status = SignInStatus.idle,
    this.errorKey,
    this.showPhoneError = false,
    this.resendSeconds = 0,
    this.verificationId,
    this.needsProfile = false,
  });

  /// The nine digits after +966, written 0-9 (for example 501234567).
  final String phone;

  /// The digits typed so far, written 0-9.
  final String code;

  final SignInStatus status;

  /// A key in assets/translations, never a text from the server.
  final String? errorKey;

  /// True after a tap on send with a number that is not valid.
  final bool showPhoneError;

  /// Seconds left before a new code may be requested.
  final int resendSeconds;

  /// The id the server gave for the current request of a code. The code is
  /// checked against it, and a resend sends it back to stay in the same
  /// request. Null before the first code, and after the server closed the
  /// request (too many wrong tries, or already used): the next code starts a
  /// new request.
  final String? verificationId;

  /// Set when the code was correct and the user has not saved the name page.
  final bool needsProfile;

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
    );
  }

  @override
  List<Object?> get props => [
    phone,
    code,
    status,
    errorKey,
    showPhoneError,
    resendSeconds,
    verificationId,
    needsProfile,
  ];
}
