import 'package:app/core/errors/failure.dart';

/// The server refused a birth date in the future (`invalid_birth_date`):
/// after the newest day on Earth for an account, after the patient's today
/// in their own zone for a patient. The date sheet stops at the newest day
/// on Earth, so this is a birth date of today where the patient's day has
/// not begun yet, or a phone with a wrong clock. Shared by onboarding, the
/// account and the circles' patient pages.
class InvalidBirthDateFailure extends Failure {
  const InvalidBirthDateFailure() : super('common.invalid_birth_date');
}

/// The server refused an account holder younger than 15 (`too_young`). The
/// sheet of one's own birth date stops 15 years back ([showBirthDateSheet]'s
/// `youngestAge`), so this is a phone with a wrong clock or an older app.
class TooYoungFailure extends Failure {
  const TooYoungFailure() : super('common.too_young');
}

/// Whether [messageKey] is one of the two refusals above, which are shown
/// under the birth date field.
bool isBirthDateError(String? messageKey) =>
    messageKey == 'common.invalid_birth_date' ||
    messageKey == 'common.too_young';
