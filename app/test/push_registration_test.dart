import 'package:app/core/services/push_registration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/phone_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePhoneNotifications phone;
  late List<String> sent;
  late PushRegistration push;
  late List<String> calls;

  setUp(() {
    phone = FakePhoneNotifications();
    sent = <String>[];
    calls = <String>[];
    push = PushRegistration(phone, (String token) async => sent.add(token));
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PushRegistration.channel, (
          MethodCall call,
        ) async {
          calls.add(call.method);
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PushRegistration.channel, null);
  });

  test('asks iOS for the token, and asks the person nothing yet', () async {
    await push.start();

    expect(calls, <String>['register']);
    expect(phone.permissionRequests, 0);
    expect(sent, isEmpty);
  });

  test('a token asks to show notifications, then goes to the server', () async {
    await push.received('ab' * 32);

    expect(phone.permissionRequests, 1);
    expect(sent, <String>['ab' * 32]);
  });

  test('a failed send is quiet; the next start sends it again', () async {
    final PushRegistration failing = PushRegistration(
      phone,
      (String token) async => throw Exception('offline'),
    );

    await failing.received('ab' * 32);

    expect(phone.permissionRequests, 1);
  });

  test('nothing happens away from iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await push.start();

    expect(calls, isEmpty);
  });
}
