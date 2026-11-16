import 'package:app/core/errors/failure.dart';

class UnknownFailure extends Failure {
  const UnknownFailure([super.messageKey = 'error.unknown']);
}

class CancelledFailure extends Failure {
  const CancelledFailure([super.messageKey = 'error.unknown']);
}
