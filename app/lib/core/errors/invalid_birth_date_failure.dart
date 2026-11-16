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
