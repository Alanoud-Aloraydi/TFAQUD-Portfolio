import 'package:app/core/errors/failure.dart';

/// The request carried no token, or one the server does not accept.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.messageKey = 'error.session_ended']);
}

/// The session itself ended: the token expired, or it was revoked.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.messageKey = 'error.session_ended']);
}

/// The person is known, and may not do this.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.messageKey = 'error.forbidden']);
}
