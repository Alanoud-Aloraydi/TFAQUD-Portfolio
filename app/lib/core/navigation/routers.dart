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
}
