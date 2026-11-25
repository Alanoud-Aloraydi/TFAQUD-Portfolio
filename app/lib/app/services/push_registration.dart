import 'dart:async';

import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/remote_push.dart';

/// Sends this phone's OneSignal subscription id to the server, for the
/// sign-in on it (PUT /accounts/me/push-subscription).
typedef SendPushSubscription = Future<void> Function(String subscriptionId);

/// Ties this phone to the signed-in account for the server's pushes
/// (OneSignal, on iOS and Android), so it can tell the person about
/// invitations, requests, answers and missed tasks while the app is closed.
///
/// It also gives the server this phone's OneSignal subscription, kept with
/// the sign-in: when OneSignal later reports the app deleted from this
/// phone, the server ends that sign-in, as a sign-out would.
class PushRegistration {
  PushRegistration(
    this._phone, {
    this._remote = const NoRemotePush(),
    this._send = _sendNothing,
  });

  final PhoneNotifications _phone;

  final RemotePush _remote;

  final SendPushSubscription _send;

  /// Set from [start] to [stop]: OneSignal tells it of a new subscription.
  RemotePushObserver? _observer;

  /// The subscription id the server has for this sign-in.
  String? _sent;

  static Future<void> _sendNothing(String subscriptionId) async {}

  /// Called once the person's home is read: signs this phone in to
  /// OneSignal as [accountId], asks once whether the app may show
  /// notifications (later calls answer at once), and sends this phone's
  /// subscription to the server, now and whenever OneSignal changes it.
  Future<void> start({required String accountId}) async {
    try {
      await _remote.signIn(accountId);
    } on Exception {
      // OneSignal not reachable now: the next start signs in again.
    }
    _sent = null;
    if (_observer == null) {
      final RemotePushObserver observer = _changed;
      _observer = observer;
      _remote.addSubscriptionObserver(observer);
    }
    await _phone.requestPermission();
    await _sendSubscription(_remote.subscriptionId);
  }

  /// The sign-in ended: nothing more is sent for it.
  void stop() {
    final RemotePushObserver? observer = _observer;
    _observer = null;
    _sent = null;
    if (observer != null) _remote.removeSubscriptionObserver(observer);
  }

  void _changed(String? subscriptionId) =>
      unawaited(_sendSubscription(subscriptionId));

  /// Sends [subscriptionId] once per sign-in, when OneSignal's servers gave
  /// it; a failed send is tried again at the next change or start.
  Future<void> _sendSubscription(String? subscriptionId) async {
    if (_observer == null ||
        subscriptionId == null ||
        !isRegisteredSubscription(subscriptionId) ||
        subscriptionId == _sent) {
      return;
    }
    _sent = subscriptionId;
    try {
      await _send(subscriptionId);
    } on Exception {
      if (_sent == subscriptionId) _sent = null;
    }
  }
}
