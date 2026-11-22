/// The appointments of one circle, their companions and their visits.
abstract final class AppointmentEndpoints {
  static String appointments(String circleId) =>
      '/circles/$circleId/appointments';
  static String appointment(String circleId, String id) =>
      '${appointments(circleId)}/$id';
  static String appointmentStatus(String circleId, String id) =>
      '${appointment(circleId, id)}/status';
  static String appointmentOutcome(String circleId, String id) =>
      '${appointment(circleId, id)}/outcome';
  static String appointmentCompanions(String circleId) =>
      '${appointments(circleId)}/companions';
  static String appointmentVisit(String circleId, String id) =>
      '${appointment(circleId, id)}/visit';
  static String appointmentVisitAudio(String circleId, String id) =>
      '${appointmentVisit(circleId, id)}/audio';
}
