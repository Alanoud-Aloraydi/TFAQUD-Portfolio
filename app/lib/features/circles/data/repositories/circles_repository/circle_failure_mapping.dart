part of '../circles_repository_data.dart';

/// The API codes that have their own text; every other error is read by
/// [FailureExceptions].
Failure _circleFailure(Object error) {
  return switch (apiErrorCodeOf(error)) {
    ApiErrorCodes.alreadyHasCircle => const AlreadyHasCircleFailure(),
    ApiErrorCodes.profileIncomplete => const ProfileIncompleteFailure(),
    ApiErrorCodes.modeConflict => const ModeConflictFailure(),
    ApiErrorCodes.tooManyCircles => const TooManyCirclesFailure(),
    _ => FailureExceptions.getException(error),
  };
}

/// The same for sending a manager invitation again or canceling it: one
/// that is no longer pending (or no longer exists) is gone either way.
Failure _invitationFailure(Object error) {
  final Failure failure = FailureExceptions.getException(error);
  return switch (apiErrorCodeOf(error)) {
    ApiErrorCodes.invitationNotPending ||
    ApiErrorCodes.invitationNotCancelable =>
      const InvitationUnavailableFailure(),
    _ when failure is NotFoundFailure => const InvitationUnavailableFailure(),
    _ => failure,
  };
}

/// The same for a request. `already_has_circle` here is about the patient,
/// not about the signed-in account, so it has its own text.
Failure _requestFailure(Object error) {
  return switch (apiErrorCodeOf(error)) {
    ApiErrorCodes.alreadyHasCircle => const PatientHasCircleFailure(),
    ApiErrorCodes.selfRequest => const SelfRequestFailure(),
    ApiErrorCodes.profileIncomplete => const ProfileIncompleteFailure(),
    ApiErrorCodes.modeConflict => const ModeConflictFailure(),
    ApiErrorCodes.tooManyCircles => const TooManyCirclesFailure(),
    _ => FailureExceptions.getException(error),
  };
}

/// The same for saving the medical file and the emergency contacts.
Failure _medicalFailure(Object error) {
  return switch (apiErrorCodeOf(error)) {
    ApiErrorCodes.tooManyContacts => const TooManyContactsFailure(),
    ApiErrorCodes.duplicateContact => const DuplicateContactFailure(),
    ApiErrorCodes.profileIncomplete => const ProfileIncompleteFailure(),
    _ => FailureExceptions.getException(error),
  };
}

/// The same for the answers of the person a request or an invitation is
/// addressed to, and for completing and canceling a request.
Failure _replyFailure(Object error) {
  return switch (apiErrorCodeOf(error)) {
    ApiErrorCodes.requestNotPending ||
    ApiErrorCodes.requestNotCancelable ||
    ApiErrorCodes.invitationNotPending ||
    ApiErrorCodes.alreadyManager ||
    ApiErrorCodes.consentRequired => const RequestUnavailableFailure(),
    ApiErrorCodes.alreadyHasCircle => const AlreadyHasCircleFailure(),
    ApiErrorCodes.acceptedRequestExists => const AcceptedRequestExistsFailure(),
    ApiErrorCodes.modeConflict => const ReplyModeConflictFailure(),
    ApiErrorCodes.tooManyCircles => const TooManyCirclesFailure(),
    ApiErrorCodes.profileIncomplete => const ProfileIncompleteFailure(),
    _ => FailureExceptions.getException(error),
  };
}
