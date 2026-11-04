import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Routes of the Flask API (backend/app/auth/routes.py,
/// backend/app/users/routes.py, backend/app/health.py,
/// backend/app/circles/routes.py).
class ApiEndpoints {
  ApiEndpoints._();

  /// Prefix shared by every route of the API.
  static const String prefix = '/api/v1';

  /// Server address from a build override or `.env`, followed by [prefix].
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    final host = (override.isNotEmpty ? override : dotenv.env['API_BASE_URL'])
        ?.trim();
    if (host == null || host.isEmpty) {
      throw StateError('API_BASE_URL is not set in .env');
    }
    final String trimmed = host.endsWith('/')
        ? host.substring(0, host.length - 1)
        : host;
    return '$trimmed$prefix';
  }

  static const String health = '/health';
  static const String home = '/home';
  static const String refreshToken = '/auth/refresh';
  static const String signOut = '/auth/sign-out';
  static const String session = '/auth/session';
  static const String requestCode = '/auth/request-code';
  static const String verifyCode = '/auth/verify-code';
  static const String profile = '/accounts/me/profile';
  static const String account = '/accounts/me';

  /// The phone's Apple push token, kept with the sign-in.
  static const String pushDevice = '/accounts/me/push-device';
  static const String selfCircle = '/circles/self';
  static const String patientCircle = '/circles/patient-without-account';
  static const String circleRequests = '/circle-requests';
  static const String invitations = '/invitations';

  /// One request: `/circle-requests/{id}`. A request is read from the list; the
  /// patient answers it with [respondCircleRequest] and completes it with
  /// [completeCircleRequest]; either side cancels it with DELETE on this path.
  static String circleRequest(String id) => '$circleRequests/$id';
  static String respondCircleRequest(String id) =>
      '${circleRequest(id)}/respond';
  static String completeCircleRequest(String id) =>
      '${circleRequest(id)}/complete';

  /// The answer to an invitation to manage a circle.
  static String respondInvitation(String id) => '$invitations/$id/respond';

  /// The medical file of a circle (the patient, the health answers and the
  /// contacts: GET; the health answers: PATCH), the basic data of the patient
  /// (PUT), the emergency contacts and the read-only emergency card.
  static String circle(String circleId) => '/circles/$circleId';
  static String circleInvitations(String circleId) =>
      '${circle(circleId)}/invitations';
  static String circleInvitation(String circleId, String invitationId) =>
      '${circleInvitations(circleId)}/$invitationId';
  static String resendCircleInvitation(String circleId, String invitationId) =>
      '${circleInvitation(circleId, invitationId)}/resend';
  static String leaveCircle(String circleId) => '${circle(circleId)}/leave';
  static String medicalProfile(String circleId) =>
      '${circle(circleId)}/medical-profile';
  static String circlePatient(String circleId) => '${circle(circleId)}/patient';
  static String emergencyContacts(String circleId) =>
      '${circle(circleId)}/emergency-contacts';
  static String emergencyContact(String circleId, String contactId) =>
      '${emergencyContacts(circleId)}/$contactId';
  static String emergencyCard(String circleId) =>
      '${circle(circleId)}/emergency-card';

  static String medicationPlans(String circleId) =>
      '/circles/$circleId/medication-plans';

  static String appointments(String circleId) =>
      '/circles/$circleId/appointments';
  static String appointment(String circleId, String id) =>
      '${appointments(circleId)}/$id';
  static String appointmentStatus(String circleId, String id) =>
      '${appointment(circleId, id)}/status';
  static String appointmentCompanions(String circleId) =>
      '${appointments(circleId)}/companions';
  static String appointmentVisit(String circleId, String id) =>
      '${appointment(circleId, id)}/visit';
  static String appointmentVisitAudio(String circleId, String id) =>
      '${appointmentVisit(circleId, id)}/audio';

  static String measurementPlans(String circleId) =>
      '/circles/$circleId/measurement-plans';
  static String measurementPlan(String circleId, String planId) =>
      '${measurementPlans(circleId)}/$planId';
  static String stopMeasurementPlan(String circleId, String planId) =>
      '${measurementPlan(circleId, planId)}/stop';
  static String measurementOccurrences(String circleId) =>
      '/circles/$circleId/measurement-occurrences';
  static String measurementReadings(String circleId) =>
      '/circles/$circleId/measurement-readings';
  static String measurementReadingsExport(String circleId) =>
      '${measurementReadings(circleId)}/export';
  static String measurementRecord(
    String circleId,
    String versionId,
    String scheduledOn,
  ) => '/circles/$circleId/measurement-records/$versionId/$scheduledOn';
  static String measurementFollowUp(String circleId, String readingId) =>
      '${measurementReadings(circleId)}/$readingId/follow-up';

  static String prayerTimes(String circleId) =>
      '/circles/$circleId/prayer-times';

  static String medicationPlan(String circleId, String planId) =>
      '${medicationPlans(circleId)}/$planId';

  static String discontinueMedication(String circleId, String planId) =>
      '${medicationPlan(circleId, planId)}/discontinue';

  static String cancelPendingMedication(String circleId, String planId) =>
      '${medicationPlan(circleId, planId)}/cancel-pending';

  static String medicationOccurrences(String circleId) =>
      '/circles/$circleId/medication-occurrences';

  static String medicationDoseRecord(
    String circleId,
    String scheduleId,
    String scheduledOn,
  ) =>
      '/circles/$circleId/medication-dose-records/'
      '$scheduleId/$scheduledOn';

  /// Routes that never carry the access token.
  static const Set<String> withoutAccessToken = <String>{
    health,
    refreshToken,
    requestCode,
    verifyCode,
  };
}
