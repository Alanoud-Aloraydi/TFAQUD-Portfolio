import 'package:app/core/errors/failure.dart';

// Failures of the two sign-in calls. Each one has its own text in
// assets/translations/ar.json (group "auth"). They come from the API codes in
// docs/api-contracts.md, section 5.

/// The code is older than five minutes. The user can ask for a new one.
class CodeExpiredFailure extends Failure {
  const CodeExpiredFailure() : super('auth.code_expired');
}

/// Three wrong codes were typed for this request. It accepts nothing more, not
/// even the right code. The user asks for a new code, which starts a new request.
class TooManyAttemptsFailure extends Failure {
  const TooManyAttemptsFailure() : super('auth.too_many_attempts');
}

/// The number had its codes for the day, or this phone or network asked for
/// too many codes in the last hour.
class TooManyCodesFailure extends Failure {
  const TooManyCodesFailure() : super('auth.too_many_codes');
}

/// A code was sent to this number a moment ago: the next one may go after
/// [seconds]. The wait grows with each code, up to 10 minutes, so someone
/// who types another person's number can only slow them down.
class ResendWaitFailure extends Failure {
  const ResendWaitFailure(this.seconds) : super('auth.resend_wait');

  final int seconds;

  @override
  List<Object?> get props => [messageKey, seconds];
}

/// Values used when the server does not say them.
abstract final class SignInFailureDefaults {
  /// The wait when a "resend_wait" answer has no number of seconds.
  static const int resendWaitSeconds = 30;
}

/// The server no longer has this request (it is unknown, or its code was already
/// accepted). The user asks for a new code, which starts a new request.
class StartAgainFailure extends Failure {
  const StartAgainFailure() : super('auth.start_again');
}

/// The SMS service could not send or check the code. Nothing was counted
/// against the user, so the same action can be tried again.
class SmsUnavailableFailure extends Failure {
  const SmsUnavailableFailure() : super('auth.sms_unavailable');
}
