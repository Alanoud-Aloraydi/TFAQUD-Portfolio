import 'package:app/core/errors/failure.dart';

class StorageFailure extends Failure {
  const StorageFailure([super.messageKey = 'error.unknown']);
}

class UploadFailure extends Failure {
  const UploadFailure([super.messageKey = 'error.unknown']);
}

class DownloadFailure extends Failure {
  const DownloadFailure([super.messageKey = 'error.unknown']);
}
