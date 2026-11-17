import 'package:app/core/errors/failure.dart';

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
