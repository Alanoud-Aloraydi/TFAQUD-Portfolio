import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:multiple_result/multiple_result.dart';

/// Turns whatever a request throws into a [Failure], so nothing is thrown
/// across the layers: the domain and the cubits only ever see a result.
mixin RepositoryGuard {
  Future<Result<T, Failure>> guard<T>(Future<T> Function() operation) async {
    try {
      return Success(await operation());
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
