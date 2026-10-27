import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Pages that need a signed-in phone.
  final List<String> protectedPages = <String>[
    Routes.today,
    Routes.plan,
    Routes.record,
    Routes.circle,
    Routes.account,
    Routes.notifications,
    Routes.onboarding,
    Routes.onboardingStart,
    Routes.addCircle,
    Routes.createSelfCircle,
    Routes.createSelfCircleHealth,
    Routes.createSelfCircleAllergies,
    Routes.createPatientCircle,
    Routes.createPatientCircleHealth,
    Routes.createPatientCircleAllergies,
    Routes.requestPatient,
    Routes.replyRequest,
    Routes.completeRequest,
    Routes.completeRequestHealth,
    Routes.completeRequestAllergies,
    Routes.medicalFile('c-1'),
    Routes.medicalFileEdit('c-1'),
    Routes.emergencyCard('c-1'),
  ];

  // Pages that anyone may open.
  const List<String> openPages = <String>[
    Routes.splash,
    Routes.auth,
    Routes.authPhone,
    Routes.authCode,
    Routes.gallery,
  ];

  group('signInRedirect', () {
    test('a phone with tokens may open every page', () {
      for (final String page in <String>[...protectedPages, ...openPages]) {
        expect(
          AppRouter.signInRedirect(page, hasTokens: true),
          isNull,
          reason: page,
        );
      }
    });

    test('a phone without tokens is sent to the sign-in page from a page that '
        'needs a sign-in', () {
      for (final String page in protectedPages) {
        expect(
          AppRouter.signInRedirect(page, hasTokens: false),
          Routes.auth,
          reason: page,
        );
      }
    });

    test('a phone without tokens may open the splash page, the sign-in pages '
        'and the gallery', () {
      for (final String page in openPages) {
        expect(
          AppRouter.signInRedirect(page, hasTokens: false),
          isNull,
          reason: page,
        );
      }
    });

    test('an address that only starts like the sign-in page is not open', () {
      expect(
        AppRouter.signInRedirect('/authentic', hasTokens: false),
        Routes.auth,
      );
    });
  });
}
