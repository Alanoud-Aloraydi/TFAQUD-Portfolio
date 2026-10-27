import 'package:equatable/equatable.dart';

/// Base failure class.
///
/// [messageKey] is a key in `assets/translations`; the screen translates it.
/// The API supplies codes, and the app shows its own Arabic text.
abstract class Failure extends Equatable {
  final String messageKey;

  const Failure([this.messageKey = 'error.unknown']);

  @override
  List<Object?> get props => [messageKey];
}

// ──────────────────────────────────────────────────────────────
// Network
// ──────────────────────────────────────────────────────────────

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

// ──────────────────────────────────────────────────────────────
// Auth
// ──────────────────────────────────────────────────────────────

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.messageKey = 'error.session_ended']);
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.messageKey = 'error.session_ended']);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.messageKey = 'error.forbidden']);
}

// ──────────────────────────────────────────────────────────────
// Data
// ──────────────────────────────────────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure([super.messageKey = 'error.unknown']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.messageKey = 'error.invalid_data']);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.messageKey = 'error.data_conflict']);
}

class EmptyDataFailure extends Failure {
  const EmptyDataFailure([super.messageKey = 'error.unknown']);
}

class FormatFailure extends Failure {
  const FormatFailure([super.messageKey = 'error.unknown']);
}

// ──────────────────────────────────────────────────────────────
// Storage
// ──────────────────────────────────────────────────────────────

class StorageFailure extends Failure {
  const StorageFailure([super.messageKey = 'error.unknown']);
}

class UploadFailure extends Failure {
  const UploadFailure([super.messageKey = 'error.unknown']);
}

class DownloadFailure extends Failure {
  const DownloadFailure([super.messageKey = 'error.unknown']);
}

// ──────────────────────────────────────────────────────────────
// Device
// ──────────────────────────────────────────────────────────────

class PermissionFailure extends Failure {
  const PermissionFailure([super.messageKey = 'error.unknown']);
}

class LocationFailure extends Failure {
  const LocationFailure([super.messageKey = 'error.unknown']);
}

class CameraFailure extends Failure {
  const CameraFailure([super.messageKey = 'error.unknown']);
}

// ──────────────────────────────────────────────────────────────
// Generic
// ──────────────────────────────────────────────────────────────

class UnknownFailure extends Failure {
  const UnknownFailure([super.messageKey = 'error.unknown']);
}

class CancelledFailure extends Failure {
  const CancelledFailure([super.messageKey = 'error.unknown']);
}
