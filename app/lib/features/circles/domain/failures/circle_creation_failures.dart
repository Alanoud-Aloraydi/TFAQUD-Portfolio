import 'package:app/core/errors/failure.dart';

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

/// The account uses Simplified Mode, which cannot manage circles. The mode of an
/// account never changes.
class ModeConflictFailure extends Failure {
  const ModeConflictFailure() : super('circles.mode_conflict');
}
