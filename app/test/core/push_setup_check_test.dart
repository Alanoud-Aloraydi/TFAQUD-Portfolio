import '../support/phone_fakes.dart';

import 'package:app/core/widgets/app_scopes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

const String _title = 'Your OneSignal SDK integration is complete!';

/// OneSignal's setup check: one dialog once the phone is registered with
/// OneSignal's servers, its button asking for the notification permission.
void main() {
  late FakeRemotePush push;
  late GlobalKey<NavigatorState> navigator;

  setUp(() {
    push = FakeRemotePush();
    navigator = GlobalKey<NavigatorState>();
  });

  Future<void> pump(WidgetTester tester, {bool enabled = true}) =>
      tester.pumpWidget(
        CupertinoApp(
          navigatorKey: navigator,
          builder: (BuildContext context, Widget? child) => PushSetupCheck(
            push: push,
            navigatorKey: navigator,
            enabled: enabled,
            child: child!,
          ),
          home: const SizedBox.shrink(),
        ),
      );

  testWidgets('nothing while the id is OneSignal\'s local one', (tester) async {
    await pump(tester);

    push.register('local-1234');
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
  });

  testWidgets('a registered phone shows the dialog once, and its button '
      'asks for the permission', (tester) async {
    await pump(tester);

    push.register('9b1c-real');
    await tester.pumpAndSettle();
    expect(find.text(_title), findsOneWidget);
    expect(push.permissionRequests, 0);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text(_title), findsNothing);
    expect(push.permissionRequests, 1);

    push.register('9b1c-again');
    await tester.pumpAndSettle();
    expect(find.text(_title), findsNothing);
  });

  testWidgets('an id there before the check started is seen too', (
    tester,
  ) async {
    push.id = '9b1c-early';

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('off in the app people use', (tester) async {
    push.id = '9b1c-real';

    await pump(tester, enabled: false);
    push.register('9b1c-real');
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
    expect(push.observers, isEmpty);
  });
}
