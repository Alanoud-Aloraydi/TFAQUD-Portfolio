import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/phone_fakes.dart';

/// The channel the iOS app delegate sends the taps on server pushes to.
const MethodChannel _channel = MethodChannel('tafaqod/push_taps');

void main() {
  group('PushRegistration', () {
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

    test(
      'a token asks to show notifications, then goes to the server',
      () async {
        await push.received('ab' * 32);

        expect(phone.permissionRequests, 1);
        expect(sent, <String>['ab' * 32]);
      },
    );

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
  });

  group('PushTapChannel', () {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();

    /// What the native side answers to `launchTap`; null when none.
    String? nativeLaunchTap;

    setUp(() {
      nativeLaunchTap = null;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _channel,
        (MethodCall call) async =>
            call.method == 'launchTap' ? nativeLaunchTap : null,
      );
    });

    tearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _channel,
        null,
      ),
    );

    /// The native side sends [kind] as a tap, as the app delegate does.
    Future<void> nativeTap(Object? kind) =>
        binding.defaultBinaryMessenger.handlePlatformMessage(
          _channel.name,
          const StandardMethodCodec().encodeMethodCall(MethodCall('tap', kind)),
          (_) {},
        );

    test('the push that launched the app is the launch tap, once', () async {
      nativeLaunchTap = 'invitation';
      final PluginPhoneNotifications phone = PluginPhoneNotifications();

      await phone.listenToPushTaps();

      expect(phone.takeLaunchTap(), '${pushTapPrefix}invitation');
      expect(phone.takeLaunchTap(), isNull);
    });

    test('a tap while a page listens reaches the taps stream', () async {
      final PluginPhoneNotifications phone = PluginPhoneNotifications();
      await phone.listenToPushTaps();
      final List<String> taps = <String>[];
      final subscription = phone.taps.listen(taps.add);
      addTearDown(subscription.cancel);

      await nativeTap('circle_request');
      await Future<void>.delayed(Duration.zero);

      expect(taps, <String>['${pushTapPrefix}circle_request']);
      expect(phone.takeLaunchTap(), isNull);
    });

    test('a tap before any page listens waits as the launch tap', () async {
      final PluginPhoneNotifications phone = PluginPhoneNotifications();
      await phone.listenToPushTaps();

      await nativeTap('dose_missed');

      expect(phone.takeLaunchTap(), '${pushTapPrefix}dose_missed');
    });

    test('an empty or non-text kind is ignored', () async {
      final PluginPhoneNotifications phone = PluginPhoneNotifications();
      await phone.listenToPushTaps();

      await nativeTap('');
      await nativeTap(42);
      await nativeTap(null);

      expect(phone.takeLaunchTap(), isNull);
    });

    test('a build without the channel still starts', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null);
      final PluginPhoneNotifications phone = PluginPhoneNotifications();

      await phone.listenToPushTaps();

      expect(phone.takeLaunchTap(), isNull);
    });
  });
}
