import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/loading/launch_curtain.dart';
import 'package:app/core/widgets/loading/pulsing_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app under the launch curtain, as main.dart puts it.
Future<void> _start(WidgetTester tester) => tester.pumpWidget(
  const MediaQuery(
    data: MediaQueryData(size: Size(400, 800)),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: LaunchCurtain(child: Text('اليوم')),
    ),
  ),
);

/// A frame past the fade: an animation ends only after its last moment.
final Duration _pastFade =
    AppMotion.launchFade + const Duration(milliseconds: 50);

void main() {
  setUp(() => LaunchCurtain.ready.value = false);
  tearDown(() => LaunchCurtain.ready.value = false);

  group('The launch logo', () {
    testWidgets('stays its time even when the app is ready, then fades away '
        'in place', (tester) async {
      LaunchCurtain.ready.value = true;
      await _start(tester);

      await tester.pump(AppMotion.launchHold - const Duration(seconds: 1));
      expect(find.byType(PulsingLogo), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(_pastFade);
      await tester.pump();

      expect(find.byType(PulsingLogo), findsNothing);
      expect(find.text('اليوم'), findsOneWidget);
    });

    testWidgets('waits for the first page when it takes longer', (
      tester,
    ) async {
      await _start(tester);

      await tester.pump(AppMotion.launchHold + const Duration(seconds: 2));
      expect(find.byType(PulsingLogo), findsOneWidget);
      LaunchCurtain.ready.value = true;
      await tester.pump();
      await tester.pump(_pastFade);
      await tester.pump();

      expect(find.byType(PulsingLogo), findsNothing);
    });

    testWidgets('breathes and never turns', (tester) async {
      await _start(tester);

      final Finder logo = find.byType(PulsingLogo);
      expect(
        find.descendant(of: logo, matching: find.byType(ScaleTransition)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: logo, matching: find.byType(RotationTransition)),
        findsNothing,
      );
      // Let the curtain go, so no timer is left.
      LaunchCurtain.ready.value = true;
      await tester.pump(AppMotion.launchHold);
      await tester.pump(_pastFade);
      await tester.pump();
    });
  });
}
