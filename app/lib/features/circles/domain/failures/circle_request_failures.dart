import 'package:app/core/errors/failure.dart';

/// The number of the request is the sender's own number.
class SelfRequestFailure extends Failure {
  const SelfRequestFailure() : super('circles.self_request');
}

/// The person the request names is already the patient of a circle, and a
/// person can be the patient of only one.
class PatientHasCircleFailure extends Failure {
  const PatientHasCircleFailure() : super('circles.patient_has_circle');
}

/// The request or the invitation is no longer open: the sender canceled it, or
/// it was answered or completed already.
class RequestUnavailableFailure extends Failure {
  const RequestUnavailableFailure() : super('circles.request_unavailable');
}

/// The patient already agreed to another request and has not finished its
/// details. Only one can be open.
class AcceptedRequestExistsFailure extends Failure {
  const AcceptedRequestExistsFailure()
    : super('circles.accepted_request_exists');
}

/// The mode of the account does not fit what the request or the invitation
/// needs. The mode of an account never changes.
class ReplyModeConflictFailure extends Failure {
  const ReplyModeConflictFailure() : super('circles.reply_mode_conflict');
}
