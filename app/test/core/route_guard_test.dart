import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
    Routes.createPatientCircle,
    Routes.requestPatient,
    Routes.replyRequest,
    Routes.completeRequest,
    Routes.medicalFile('c-1'),
    Routes.medicalFileEdit('c-1'),
    Routes.emergencyCard('c-1'),
    Routes.simplifiedMode,
    Routes.simplifiedMedicalFile('c-1'),
    Routes.simplifiedMedicalFileEdit('c-1'),
    Routes.simplifiedEmergencyCard('c-1'),
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

  group('requireExtra', () {
    /// A router with one page that needs an `extra` of type [String], and
    /// the page it falls back to.
    GoRouter routerWith() => GoRouter(
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (context, state) => const Text('way in')),
        GoRoute(
          path: '/needs',
          redirect: requireExtra<String>('/'),
          builder: (context, state) => Text('page ${state.extra}'),
        ),
      ],
    );

    testWidgets('a page opened without its extra goes to the fallback', (
      tester,
    ) async {
      final GoRouter router = routerWith();
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go('/needs');
      await tester.pumpAndSettle();

      expect(find.text('way in'), findsOneWidget);
    });

    testWidgets('an extra of another type is the same as none', (tester) async {
      final GoRouter router = routerWith();
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go('/needs', extra: 7);
      await tester.pumpAndSettle();

      expect(find.text('way in'), findsOneWidget);
    });

    testWidgets('a page opened with its extra is built from it', (
      tester,
    ) async {
      final GoRouter router = routerWith();
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go('/needs', extra: 'the choice');
      await tester.pumpAndSettle();

      expect(find.text('page the choice'), findsOneWidget);
    });
  });
}
