import 'package:app/core/services/remote_push.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// The OneSignal app the server's pushes come from. Not a secret: it only
/// names the app; sending needs the API key, which only the server has.
const String oneSignalAppId = '50e5581f-1938-47b7-a23a-c65c70c4a26d';

/// [RemotePush] through the OneSignal SDK (onesignal_flutter). On a platform
/// OneSignal has no SDK for (web, desktop) every call does nothing.
class OneSignalRemotePush implements RemotePush {
  /// The observers given, by the SDK's observer each is wrapped in, so the
  /// wrapper lives as long as the caller's observer.
  final Map<RemotePushObserver, OnPushSubscriptionChangeObserver> _observers =
      <RemotePushObserver, OnPushSubscriptionChangeObserver>{};

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
  }

  @override
  Future<void> signIn(String accountId) async {
    if (!_started) return;
    await OneSignal.login(accountId);
  }

  @override
  Future<void> signOut() async {
    if (!_started) return;
    await OneSignal.logout();
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
  Future<bool> requestPermission() async {
    if (!_started) return false;
    return OneSignal.Notifications.requestPermission(true);
  }
}
