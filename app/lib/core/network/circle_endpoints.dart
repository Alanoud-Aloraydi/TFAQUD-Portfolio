/// One care circle's routes of the API (backend/app/circles/routes.py): the
/// circle, its members and invitations, its medical file, its emergency
/// card and its prayer times.
abstract final class CircleEndpoints {
  static const String selfCircle = '/circles/self';
  static const String patientCircle = '/circles/patient-without-account';

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
  static String circleMember(String circleId, String accountId) =>
      '${circle(circleId)}/members/$accountId';

  /// Who leads the circle («قائد الدائرة»).
  static String circleLeader(String circleId) => '${circle(circleId)}/leader';

  /// «ذكّرني لاحقًا», shared by the circle.
  static String taskSnoozes(String circleId) =>
      '${circle(circleId)}/task-snoozes';
  static String medicalProfile(String circleId) =>
      '${circle(circleId)}/medical-profile';
  static String circlePatient(String circleId) => '${circle(circleId)}/patient';
  static String patientPhoto(String circleId) =>
      '${circlePatient(circleId)}/photo';
  static String patientAvatar(String circleId) =>
      '${circlePatient(circleId)}/avatar';
  static String memberPhoto(String circleId, String accountId) =>
      '${circle(circleId)}/members/$accountId/photo';
  static String emergencyContacts(String circleId) =>
      '${circle(circleId)}/emergency-contacts';
  static String emergencyContact(String circleId, String contactId) =>
      '${emergencyContacts(circleId)}/$contactId';
  static String emergencyCard(String circleId) =>
      '${circle(circleId)}/emergency-card';

  static String prayerTimes(String circleId) =>
      '/circles/$circleId/prayer-times';
}

/// The requests to a patient and the invitations to manage a circle, and
/// the bell's answered ones (backend/app/circles/routes.py).
abstract final class CircleRequestEndpoints {
  static const String circleRequests = '/circle-requests';
  static const String invitations = '/invitations';

  /// The invitations and requests answered in the last 30 days, for the
  /// bell's «السابقة».
  static const String previousNotifications = '/notifications/previous';

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
}
