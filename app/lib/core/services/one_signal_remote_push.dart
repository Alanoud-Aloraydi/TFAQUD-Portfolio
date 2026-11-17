import 'dart:async';

import 'package:app/core/services/push_target.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// The OneSignal app the pushes come from; no secret (sending needs a key).
const String oneSignalAppId = '50e5581f-1938-47b7-a23a-c65c70c4a26d';

/// [RemotePush] through the OneSignal SDK (onesignal_flutter). On a platform
/// OneSignal has no SDK for (web, desktop) every call does nothing.
class OneSignalRemotePush implements RemotePush {
  /// Each observer given, by the SDK observer that wraps it (kept alive).
  final Map<RemotePushObserver, OnPushSubscriptionChangeObserver> _observers =
      <RemotePushObserver, OnPushSubscriptionChangeObserver>{};
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _started = false;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<void> initialize() async {
    if (_started || !_supported) return;
    _started = true;
    // Everything in a debug build, only errors in the app people use.
    await OneSignal.Debug.setLogLevel(
      kDebugMode ? OSLogLevel.verbose : OSLogLevel.error,
    );
    await OneSignal.initialize(oneSignalAppId);
    // A push's data has its `kind` and item (targets.py, push_target.dart).
    OneSignal.Notifications.addClickListener((OSNotificationClickEvent tap) {
      final String? text = pushTapText(tap.notification.additionalData);
      if (text != null) _taps.add(text);
    });
  }

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> signIn(String accountId) async {
    if (_started) await OneSignal.login(accountId);
  }

  @override
  Future<void> signOut() async {
    if (_started) await OneSignal.logout();
  }

  @override
  String? get subscriptionId =>
      _started ? OneSignal.User.pushSubscription.id : null;

  @override
  void addSubscriptionObserver(RemotePushObserver observer) {
    if (!_started || _observers.containsKey(observer)) return;
    void changed(OSPushSubscriptionChangedState state) =>
        observer(state.current.id);
    _observers[observer] = changed;
    OneSignal.User.pushSubscription.addObserver(changed);
  }

  @override
  void removeSubscriptionObserver(RemotePushObserver observer) {
    final OnPushSubscriptionChangeObserver? changed = _observers.remove(
      observer,
    );
    if (changed != null) {
      OneSignal.User.pushSubscription.removeObserver(changed);
    }
  }

  @override
  Future<bool> requestPermission() async =>
      _started && await OneSignal.Notifications.requestPermission(true);

  @override
  Future<void> setWanted(bool wanted) async {
    if (!_started) return;
    final push = OneSignal.User.pushSubscription;
    if (!wanted) return push.optOut();
    // optIn would ask for a permission the phone lacks; the switch asks.
    if (OneSignal.Notifications.permission) await push.optIn();
  }
}
