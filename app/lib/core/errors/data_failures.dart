import 'package:app/core/errors/failure.dart';

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
