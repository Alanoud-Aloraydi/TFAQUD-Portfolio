import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/failures/sign_in_failures.dart';

/// True when the server will accept nothing more on this request: the three
/// wrong tries are used, or the request is unknown or already finished.
/// Asking for a code again must then start a new request.
bool requestIsClosed(Failure failure) =>
    failure is TooManyAttemptsFailure || failure is StartAgainFailure;
