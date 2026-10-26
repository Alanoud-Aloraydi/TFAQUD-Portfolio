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
