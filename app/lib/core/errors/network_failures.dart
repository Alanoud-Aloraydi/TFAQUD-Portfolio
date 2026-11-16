import 'package:app/core/errors/failure.dart';

class ServerFailure extends Failure {
  const ServerFailure([super.messageKey = 'error.server']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.messageKey = 'error.network']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.messageKey = 'error.timeout']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.messageKey = 'error.resource_not_found']);
}
