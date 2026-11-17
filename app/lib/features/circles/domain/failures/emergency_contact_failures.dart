import 'package:app/core/errors/failure.dart';

/// The patient has five emergency contacts already, the most the server keeps.
class TooManyContactsFailure extends Failure {
  const TooManyContactsFailure() : super('circles.too_many_contacts');
}

/// The phone number is already one of the patient's emergency contacts.
class DuplicateContactFailure extends Failure {
  const DuplicateContactFailure() : super('circles.duplicate_contact');
}
