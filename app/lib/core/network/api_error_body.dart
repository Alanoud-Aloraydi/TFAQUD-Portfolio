export 'package:app/core/network/api_error_readers.dart';

/// Error codes the Flask API returns (backend/app/errors.py and services).
abstract class ApiErrorCodes {
  ApiErrorCodes._();

  static const String missingToken = 'missing_token';
  static const String invalidToken = 'invalid_token';
  static const String accessTokenExpired = 'access_token_expired';
  static const String sessionRevoked = 'session_revoked';
  static const String invalidRefreshToken = 'invalid_refresh_token';
  static const String forbidden = 'forbidden';
  static const String notFound = 'not_found';
  static const String badRequest = 'bad_request';
  static const String invalidJson = 'invalid_json';
  static const String validationError = 'validation_error';
  static const String internalError = 'internal_error';
  static const String dataConflict = 'data_conflict';
  static const String medicationPeriodConflict = 'medication_period_conflict';
  static const String medicationVersionConflict = 'medication_version_conflict';
  static const String medicationDiscontinued = 'medication_stopped';
  static const String medicationRevisionDate = 'medication_revision_date';
  static const String medicationStartInPast = 'medication_start_in_past';
  static const String doseRecordConflict = 'dose_record_conflict';
  static const String futureDoseRecord = 'future_dose_record';
  static const String futureTakenTime = 'future_taken_time';
  static const String doseTooOld = 'dose_too_old';
  static const String appointmentTimeInPast = 'appointment_time_in_past';
  static const String appointmentNotStarted = 'appointment_not_started';
  static const String appointmentMissed = 'appointment_missed';
  static const String appointmentChanged = 'appointment_changed';
  static const String appointmentAlreadyClosed = 'appointment_already_closed';
  static const String appointmentInvalidCompanion =
      'appointment_invalid_companion';
  static const String appointmentInvalidAudio = 'appointment_invalid_audio';
  static const String appointmentVisitNotCompleted =
      'appointment_visit_not_completed';
  static const String appointmentVisitFilled = 'appointment_visit_filled';
  static const String appointmentOutcomeClosed = 'appointment_outcome_closed';

  // Measurements (backend/app/measurements/service.py).
  static const String measurementActivePlanExists =
      'measurement_active_plan_exists';
  static const String measurementStartInPast = 'measurement_start_in_past';
  static const String measurementPlanChanged = 'measurement_plan_changed';
  static const String measurementEffectiveDate = 'measurement_effective_date';
  static const String measurementRecordConflict = 'measurement_record_conflict';
  static const String futureMeasurement = 'future_measurement';
  static const String futureMeasurementTask = 'future_measurement_task';
  static const String measurementWithinTarget = 'measurement_within_target';

  // Sign-in (backend/app/auth/sign_in.py) and the profile.
  static const String verificationNotFound = 'verification_not_found';
  static const String invalidCode = 'invalid_code';
  static const String codeExpired = 'code_expired';
  static const String codeAlreadyUsed = 'code_already_used';
  static const String tooManyAttempts = 'too_many_attempts';
  static const String tooManyCodes = 'too_many_codes';
  static const String resendWait = 'resend_wait';
  static const String smsUnavailable = 'sms_unavailable';

  // Circle creation (backend/app/care.py); an account holder is 15 or older.
  static const String alreadyHasCircle = 'already_has_circle';
  static const String profileIncomplete = 'profile_incomplete';
  static const String invalidBirthDate = 'invalid_birth_date';
  static const String tooYoung = 'too_young';
  static const String modeConflict = 'mode_conflict';
  // Six circles per person, open requests included (backend/app/care).
  static const String tooManyCircles = 'too_many_circles';
  // Circle requests (backend/app/care.py).
  static const String selfRequest = 'self_request';
  static const String requestNotPending = 'request_not_pending';
  static const String requestNotCancelable = 'request_not_cancelable';
  static const String acceptedRequestExists = 'accepted_request_exists';
  static const String consentRequired = 'consent_required';

  // Invitations to manage a circle (backend/app/care.py).
  static const String invitationNotPending = 'invitation_not_pending';
  static const String invitationNotCancelable = 'invitation_not_cancelable';
  static const String alreadyManager = 'already_manager';
  static const String selfInvitation = 'self_invitation';

  // Leaving a circle that the leave would delete (backend/app/care.py),
  // deleting the account (backend/app/users), and the emergency contacts
  // (backend/app/medical.py).
  static const String confirmationRequired = 'confirmation_required';
  static const String patientChoiceRequired = 'patient_choice_required';
  static const String lastManager = 'last_manager';
  static const String tooManyContacts = 'too_many_contacts';
  static const String duplicateContact = 'duplicate_contact';
}
