import 'package:app/core/errors/failure.dart';

/// The code the user typed is wrong. The user may try again.
class InvalidCodeFailure extends Failure {
  const InvalidCodeFailure() : super('auth.code_wrong');
}
