import 'package:dio/dio.dart' show DioException;

/// Error codes returned by the Flask API (backend/app/errors.py,
/// backend/app/auth and backend/app/care.py).
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
  static const String medicationDiscontinued = 'medication_discontinued';
  static const String medicationRevisionDate = 'medication_revision_date';
  static const String doseRecordConflict = 'dose_record_conflict';

  // Sign-in (backend/app/auth/sign_in.py) and the profile.
  static const String verificationNotFound = 'verification_not_found';
  static const String userNotFound = 'user_not_found';
  static const String invalidCode = 'invalid_code';
  static const String codeExpired = 'code_expired';
  static const String codeAlreadyUsed = 'code_already_used';
  static const String tooManyAttempts = 'too_many_attempts';
  static const String tooManyCodes = 'too_many_codes';
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
  static const String alreadyManager = 'already_manager';

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
