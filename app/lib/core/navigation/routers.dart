class Routes {
  Routes._();

  static const String splash = '/';
  static const String today = '/today';
  static const String plan = '/plan';
  static const String record = '/record';
  static const String circle = '/circle';
  static const String account = '/account';
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

  // The circle of the signed-in person, created for themselves in three steps:
  // basic details, health condition, allergies.
  static const String createSelfCircle = '/circles/new/self';
  static const String createSelfCircleHealth = '/circles/new/self/health';
  static const String createSelfCircleAllergies = '/circles/new/self/allergies';

  // The circle of a patient who does not use the app, in the same three steps.
  static const String createPatientCircle = '/circles/new/patient';
  static const String createPatientCircleHealth = '/circles/new/patient/health';
  static const String createPatientCircleAllergies =
      '/circles/new/patient/allergies';

  // A request to a patient who uses the app: the phone number page. The page
  // shows the waiting state itself once the request is sent.
  static const String requestPatient = '/circles/new/request';

  // The patient's side of a request, opened from the notifications. The page of
  // the request takes the answer; after "agree" the three steps of the basic
  // data (name from the account, health condition, allergies) create the circle.
  static const String replyRequest = '/notifications/request';
  static const String completeRequest = '/circles/complete';
  static const String completeRequestHealth = '/circles/complete/health';
  static const String completeRequestAllergies = '/circles/complete/allergies';

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
}
