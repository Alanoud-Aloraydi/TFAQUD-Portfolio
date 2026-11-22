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

  group('The subscription of this phone, for the sign-in', () {
    late FakePhoneNotifications phone;
    late FakeRemotePush remote;
    late List<String> sent;
    late PushRegistration push;

    setUp(() {
      phone = FakePhoneNotifications();
      remote = FakeRemotePush();
      sent = <String>[];
      push = PushRegistration(
        phone,
        remote: remote,
        send: (String id) async => sent.add(id),
      );
    });

    test('the subscription OneSignal already gave is sent at once', () async {
      remote.id = 'sub-1';

      await push.start(accountId: 'acc-1');

      expect(sent, <String>['sub-1']);
    });

    test('one that comes later is sent when it comes, once', () async {
      await push.start(accountId: 'acc-1');
      expect(sent, isEmpty);

      remote
        ..register('local-7')
        ..register('sub-2')
        ..register('sub-2');
      await Future<void>.delayed(Duration.zero);

      // OneSignal's own `local-` id is not one its servers know.
      expect(sent, <String>['sub-2']);
    });

    test('each sign-in sends it again, for its own session', () async {
      remote.id = 'sub-1';
      await push.start(accountId: 'acc-1');

      push.stop();
      await push.start(accountId: 'acc-2');

      expect(sent, <String>['sub-1', 'sub-1']);
      expect(remote.observers, hasLength(1));
    });

    test('after the sign-in ends nothing is sent', () async {
      await push.start(accountId: 'acc-1');

      push.stop();
      remote.register('sub-3');
      await Future<void>.delayed(Duration.zero);

      expect(sent, isEmpty);
      expect(remote.observers, isEmpty);
    });

    test('a failed send is tried again at the next change', () async {
      int tries = 0;
      final PushRegistration offline = PushRegistration(
        phone,
        remote: remote,
        send: (String id) async {
          tries++;
          if (tries == 1) throw Exception('offline');
          sent.add(id);
        },
      );
      remote.id = 'sub-1';

      await offline.start(accountId: 'acc-1');
      remote.register('sub-1');
      await Future<void>.delayed(Duration.zero);

      expect(tries, 2);
      expect(sent, <String>['sub-1']);
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

    test("a reminder from the server reaches the page as the phone's own "
        'reminder would', () async {
      final List<String> taps = <String>[];
      final StreamSubscription<String> subscription = phone.taps.listen(
        taps.add,
      );
      addTearDown(subscription.cancel);

      pushes
        ..add('${serverReminderTapPrefix}dose:c-1')
        ..add('$serverReminderTapPrefix${snoozeTapPrefix}dose:c-1');
      await Future<void>.delayed(Duration.zero);

      expect(taps, <String>['dose:c-1', '${snoozeTapPrefix}dose:c-1']);
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

    test('a reminder tapped while no page listens waits as the launch tap; '
        'the latest tap wins', () {
      // The phone's own reminder that opened the app arrives once its
      // plugin is ready, before «اليوم» or the simplified page listens.
      phone
        ..deliverTap('dose:c-1')
        ..deliverTap('measurement:c-1');

      expect(phone.takeLaunchTap(), 'measurement:c-1');
      expect(phone.takeLaunchTap(), isNull);
    });

    test('a reminder tapped while a page listens reaches it at once', () async {
      final List<String> taps = <String>[];
      final StreamSubscription<String> subscription = phone.taps.listen(
        taps.add,
      );
      addTearDown(subscription.cancel);

      phone.deliverTap('dose:c-1');
      await Future<void>.delayed(Duration.zero);

      expect(taps, <String>['dose:c-1']);
      expect(phone.takeLaunchTap(), isNull);
    });

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
