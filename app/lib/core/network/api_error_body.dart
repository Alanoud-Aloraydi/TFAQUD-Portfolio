import 'package:dio/dio.dart' show DioException;

/// Error codes returned by the Flask API (backend/app/errors.py,
/// backend/app/auth, backend/app/care.py and the feature services).
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
  static const String appointmentTimeInPast = 'appointment_time_in_past';
  static const String appointmentNotStarted = 'appointment_not_started';
  static const String appointmentChanged = 'appointment_changed';
  static const String appointmentAlreadyClosed = 'appointment_already_closed';
  static const String appointmentInvalidCompanion =
      'appointment_invalid_companion';
  static const String appointmentInvalidAudio = 'appointment_invalid_audio';
  static const String appointmentVisitNotCompleted =
      'appointment_visit_not_completed';

  // Measurements (backend/app/measurements/service.py).
  static const String measurementActivePlanExists =
      'measurement_active_plan_exists';
  static const String measurementStartInPast = 'measurement_start_in_past';
  static const String measurementPlanChanged = 'measurement_plan_changed';
  static const String measurementEffectiveDate = 'measurement_effective_date';
  static const String measurementTargetRequired = 'measurement_target_required';
  static const String measurementTargetFromPlan =
      'measurement_target_from_plan';
  static const String measurementRecordConflict = 'measurement_record_conflict';
  static const String futureMeasurement = 'future_measurement';
  static const String futureMeasurementTask = 'future_measurement_task';
  static const String measurementWithinTarget = 'measurement_within_target';
  static const String measurementNoTarget = 'measurement_no_target';

  // Sign-in (backend/app/auth/sign_in.py) and the profile.
  static const String verificationNotFound = 'verification_not_found';
  static const String invalidCode = 'invalid_code';
  static const String codeExpired = 'code_expired';
  static const String codeAlreadyUsed = 'code_already_used';
  static const String tooManyAttempts = 'too_many_attempts';
  static const String tooManyCodes = 'too_many_codes';
  static const String resendWait = 'resend_wait';
  static const String smsUnavailable = 'sms_unavailable';

  // Circle creation (backend/app/care.py).
  static const String alreadyHasCircle = 'already_has_circle';
  static const String profileIncomplete = 'profile_incomplete';
  static const String invalidBirthDate = 'invalid_birth_date';
  static const String modeConflict = 'mode_conflict';

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

  // Leaving a circle that the leave would delete (backend/app/care.py).
  static const String confirmationRequired = 'confirmation_required';

  // Deleting the account (backend/app/users).
  static const String patientChoiceRequired = 'patient_choice_required';
  static const String lastManager = 'last_manager';

  // Emergency contacts (backend/app/medical.py).
  static const String tooManyContacts = 'too_many_contacts';
  static const String duplicateContact = 'duplicate_contact';
}

/// Reads `error.code` from a body of the form `{"error": {"code": ...}}`.
/// Returns null when the body does not have that shape.
String? apiErrorCode(Object? body) {
  if (body is Map) {
    final Object? error = body['error'];
    if (error is Map) {
      final Object? code = error['code'];
      if (code is String) return code;
    }
  }
  return null;
}

/// The API error code inside [error], when [error] is a [DioException] whose
/// response has the API error body. Returns null for any other error.
String? apiErrorCodeOf(Object error) =>
    error is DioException ? apiErrorCode(error.response?.data) : null;

/// The `error.retry_after_seconds` of an API error inside [error], when the
/// server says how long to wait. Null otherwise.
int? apiRetryAfterOf(Object error) {
  if (error is! DioException) return null;
  final Object? body = error.response?.data;
  if (body is Map) {
    final Object? inner = body['error'];
    if (inner is Map) {
      final Object? seconds = inner['retry_after_seconds'];
      if (seconds is int && seconds > 0) return seconds;
    }
  }
  return null;
}
