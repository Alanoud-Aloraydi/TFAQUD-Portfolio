/// The addresses of the medications, measurements and appointments of one
/// circle: the `...Path` constants are the patterns of the router; the
/// functions build the address of one plan or appointment.
abstract final class CareItemRoutes {
  static const String medicationNewPath = '/circles/:circleId/medications/new';
  static const String medicationDetailsPath =
      '/circles/:circleId/medications/:planId';
  static const String medicationEditPath =
      '/circles/:circleId/medications/:planId/edit';

  static String newMedication(String circleId) =>
      '/circles/$circleId/medications/new';
  static String medicationDetails(String circleId, String planId) =>
      '/circles/$circleId/medications/$planId';
  static String editMedication(String circleId, String planId) =>
      '/circles/$circleId/medications/$planId/edit';
  static const String measurementNewPath =
      '/circles/:circleId/measurements/new';
  static const String measurementEditPath =
      '/circles/:circleId/measurements/:planId/edit';
  static String newMeasurement(String circleId) =>
      '/circles/$circleId/measurements/new';
  static String editMeasurement(String circleId, String planId) =>
      '/circles/$circleId/measurements/$planId/edit';
  static const String appointmentNewPath =
      '/circles/:circleId/appointments/new';
  static const String appointmentEditPath =
      '/circles/:circleId/appointments/:appointmentId/edit';
  static String newAppointment(String circleId) =>
      '/circles/$circleId/appointments/new';
  static String editAppointment(String circleId, String appointmentId) =>
      '/circles/$circleId/appointments/$appointmentId/edit';
  static const String appointmentVisitPath =
      '/circles/:circleId/appointments/:appointmentId/visit';
  static String appointmentVisit(String circleId, String appointmentId) =>
      '/circles/$circleId/appointments/$appointmentId/visit';
}
