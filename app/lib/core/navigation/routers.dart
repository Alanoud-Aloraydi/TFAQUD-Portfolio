class Routes {
  Routes._();

  static const String splash = '/';
  static const String today = '/today';
  static const String plan = '/plan';
  static const String record = '/record';
  static const String circle = '/circle';
  static const String account = '/account';
  static const String accountEdit = '/account/edit';
  static const String notifications = '/notifications';
  static const String gallery = '/gallery';

  // Sign in: welcome, phone number, code.
  static const String auth = '/auth';
  static const String authPhone = '/auth/phone';
  static const String authCode = '/auth/code';

  // Account setup after the first sign-in: name, how to start.
  static const String onboarding = '/onboarding';
  static const String onboardingStart = '/onboarding/start';

  // The same "how do you want to start?" page, opened by the "+" next to the
  // circles to add another circle.
  static const String addCircle = '/circles/new';
  static const String home = '/home';

  // The circle of the signed-in person, created for themselves on one page:
  // its name. The medical file is filled later.
  static const String createSelfCircle = '/circles/new/self';

  // The circle of a patient who does not use the app, on one page.
  static const String createPatientCircle = '/circles/new/patient';

  // A request to a patient who uses the app: the phone number page. The page
  // shows the waiting state itself once the request is sent.
  static const String requestPatient = '/circles/new/request';

  // The patient's side of a request, opened from the notifications. The page of
  // the request takes the answer; after "agree" one page creates the circle
  // (the name and, since onboarding, the birth date and city come from the
  // account).
  static const String replyRequest = '/notifications/request';
  static const String completeRequest = '/circles/complete';

  // Inside a circle: its medical file (read, then edit) and its emergency
  // card. The id of the circle is part of the address, so the pages work after
  // a reload in the browser. The `...Path` constants are the patterns of the
  // router; the functions build the address of one circle.
  static const String medicalFilePath = '/circle/:circleId/medical-file';
  static const String medicalFileEditPath =
      '/circle/:circleId/medical-file/edit';
  static const String emergencyCardPath = '/circle/:circleId/emergency-card';

  static String medicalFile(String circleId) =>
      '/circle/$circleId/medical-file';
  static String medicalFileEdit(String circleId) =>
      '/circle/$circleId/medical-file/edit';
  static String emergencyCard(String circleId) =>
      '/circle/$circleId/emergency-card';

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
