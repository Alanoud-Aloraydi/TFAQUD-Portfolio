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
  static const String home = '/home';
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
