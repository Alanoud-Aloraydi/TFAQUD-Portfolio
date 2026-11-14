import 'dart:async';

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/phone_fakes.dart';

void main() {
  group('PushRegistration', () {
    late FakePhoneNotifications phone;
    late FakeRemotePush remote;
    late PushRegistration push;

    setUp(() {
      phone = FakePhoneNotifications();
      remote = FakeRemotePush();
      push = PushRegistration(phone, remote: remote);
    });

    test('ties the account to this phone in OneSignal, then asks to show '
        'notifications', () async {
      await push.start(accountId: 'acc-1');

      expect(remote.signIns, <String>['acc-1']);
      expect(phone.permissionRequests, 1);
    });

    test('OneSignal out of reach still asks for the permission', () async {
      final PushRegistration failing = PushRegistration(
        phone,
        remote: _FailingRemotePush(),
      );

      await failing.start(accountId: 'acc-1');

      expect(phone.permissionRequests, 1);
    });
  });

  group('Push taps', () {
    late StreamController<String> pushes;
    late PluginPhoneNotifications phone;

    setUp(() {
      pushes = StreamController<String>.broadcast();
      phone = PluginPhoneNotifications(pushTaps: pushes.stream)
        ..listenToPushTaps();
    });

    tearDown(() => pushes.close());

    test('a tap while a page listens reaches the taps stream', () async {
      final List<String> taps = <String>[];
      final StreamSubscription<String> subscription = phone.taps.listen(
        taps.add,
      );
      addTearDown(subscription.cancel);

      pushes.add('circle_request');
      await Future<void>.delayed(Duration.zero);

      expect(taps, <String>['${pushTapPrefix}circle_request']);
      expect(phone.takeLaunchTap(), isNull);
    });

    test(
      'the push that opened the app waits as the launch tap, once',
      () async {
        pushes.add('invitation');
        await Future<void>.delayed(Duration.zero);

        expect(phone.takeLaunchTap(), '${pushTapPrefix}invitation');
        expect(phone.takeLaunchTap(), isNull);
      },
    );

    test('an empty kind is ignored', () async {
      pushes.add('');
      await Future<void>.delayed(Duration.zero);

      expect(phone.takeLaunchTap(), isNull);
    });
  });
}

/// OneSignal that cannot be reached.
class _FailingRemotePush extends NoRemotePush {
  @override
  Future<void> signIn(String accountId) async =>
      throw Exception('OneSignal unreachable');
}
