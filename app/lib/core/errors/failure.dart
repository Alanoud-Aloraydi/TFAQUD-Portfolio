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

/// Represents a server failure condition.
class ServerFailure extends Failure {
  const ServerFailure([super.messageKey = 'error.server']);
}

/// Represents a network failure condition.
class NetworkFailure extends Failure {
  const NetworkFailure([super.messageKey = 'error.network']);
}

/// Represents a timeout failure condition.
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.messageKey = 'error.timeout']);
}

/// Represents a not found failure condition.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.messageKey = 'error.resource_not_found']);
}

// ──────────────────────────────────────────────────────────────
// Auth
// ──────────────────────────────────────────────────────────────

/// Represents a unauthorized failure condition.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.messageKey = 'error.session_ended']);
}

/// Represents a session expired failure condition.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.messageKey = 'error.session_ended']);
}

/// Represents a forbidden failure condition.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.messageKey = 'error.forbidden']);
}

// ──────────────────────────────────────────────────────────────
// Data
// ──────────────────────────────────────────────────────────────

/// Represents a cache failure condition.
class CacheFailure extends Failure {
  const CacheFailure([super.messageKey = 'error.unknown']);
}

/// Represents a validation failure condition.
class ValidationFailure extends Failure {
  const ValidationFailure([super.messageKey = 'error.invalid_data']);
}

/// Represents a conflict failure condition.
class ConflictFailure extends Failure {
  const ConflictFailure([super.messageKey = 'error.data_conflict']);
}

/// Represents a empty data failure condition.
class EmptyDataFailure extends Failure {
  const EmptyDataFailure([super.messageKey = 'error.unknown']);
}

/// Represents a format failure condition.
class FormatFailure extends Failure {
  const FormatFailure([super.messageKey = 'error.unknown']);
}

// ──────────────────────────────────────────────────────────────
// Storage
// ──────────────────────────────────────────────────────────────

/// Represents a storage failure condition.
class StorageFailure extends Failure {
  const StorageFailure([super.messageKey = 'error.unknown']);
}

/// Represents a upload failure condition.
class UploadFailure extends Failure {
  const UploadFailure([super.messageKey = 'error.unknown']);
}

/// Represents a download failure condition.
class DownloadFailure extends Failure {
  const DownloadFailure([super.messageKey = 'error.unknown']);
}

// ──────────────────────────────────────────────────────────────
// Device
// ──────────────────────────────────────────────────────────────

/// Represents a permission failure condition.
class PermissionFailure extends Failure {
  const PermissionFailure([super.messageKey = 'error.unknown']);
}

/// Represents a location failure condition.
class LocationFailure extends Failure {
  const LocationFailure([super.messageKey = 'error.unknown']);
}

/// Represents a camera failure condition.
class CameraFailure extends Failure {
  const CameraFailure([super.messageKey = 'error.unknown']);
}

// ──────────────────────────────────────────────────────────────
// Generic
// ──────────────────────────────────────────────────────────────

/// Represents a unknown failure condition.
class UnknownFailure extends Failure {
  const UnknownFailure([super.messageKey = 'error.unknown']);
}

/// Represents a cancelled failure condition.
class CancelledFailure extends Failure {
  const CancelledFailure([super.messageKey = 'error.unknown']);
}
