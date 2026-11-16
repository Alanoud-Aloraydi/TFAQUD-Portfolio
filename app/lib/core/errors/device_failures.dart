import 'package:app/core/errors/failure.dart';

class PermissionFailure extends Failure {
  const PermissionFailure([super.messageKey = 'error.unknown']);
}

class LocationFailure extends Failure {
  const LocationFailure([super.messageKey = 'error.unknown']);
}

class CameraFailure extends Failure {
  const CameraFailure([super.messageKey = 'error.unknown']);
}
