import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:multiple_result/multiple_result.dart';

/// The measurement and appointment repositories throw; this turns their
/// errors into the same failures the other features return.
Future<Result<T, Failure>> attemptResult<T extends Object>(
  Future<T> Function() call,
) async {
  try {
    return Success(await call());
  } catch (error) {
    return Error(FailureExceptions.getException(error));
  }
}
