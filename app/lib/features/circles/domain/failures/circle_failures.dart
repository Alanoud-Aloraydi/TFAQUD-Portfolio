import 'package:app/core/errors/failure.dart';

// Failures of the circle calls that have their own text in
// assets/translations/ar.json (group "circles"). They come from the API codes
// in docs/api-contracts.md, "Circles, requests, invitations and the medical
// file".

/// The account is already the patient of a circle, and an account can be the
/// patient of only one. Also the answer to a second try after the first one
/// was saved but its answer was lost.
class AlreadyHasCircleFailure extends Failure {
  const AlreadyHasCircleFailure() : super('circles.already_has_circle');
}

/// The account has no names yet. The account setup pages come first.
class ProfileIncompleteFailure extends Failure {
  const ProfileIncompleteFailure() : super('circles.profile_incomplete');
}

/// The birth date is in the future. The date picker does not offer such a
/// date, so this is only a phone with a wrong clock.
class InvalidBirthDateFailure extends Failure {
  const InvalidBirthDateFailure() : super('circles.invalid_birth_date');
}

/// The account uses Simplified Mode, which cannot manage circles. The mode of an
/// account never changes.
class ModeConflictFailure extends Failure {
  const ModeConflictFailure() : super('circles.mode_conflict');
}

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

/// Deleting the account needs a choice first: the account is the patient of a
/// circle, which can be deleted or kept for the other managers.
class PatientChoiceRequiredFailure extends Failure {
  const PatientChoiceRequiredFailure()
    : super('circles.patient_choice_required');
}

/// Deleting the account would leave a circle with no manager. The account
/// page asks whether those circles are deleted too.
class LastManagerFailure extends Failure {
  const LastManagerFailure() : super('circles.last_manager');
}

/// The patient has five emergency contacts already, the most the server keeps.
class TooManyContactsFailure extends Failure {
  const TooManyContactsFailure() : super('circles.too_many_contacts');
}

/// The phone number is already one of the patient's emergency contacts.
class DuplicateContactFailure extends Failure {
  const DuplicateContactFailure() : super('circles.duplicate_contact');
}
