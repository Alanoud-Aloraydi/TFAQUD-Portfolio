import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// The OneSignal app the server's pushes come from. Not a secret: it only
/// names the app; sending needs the API key, which only the server has.
const String oneSignalAppId = '50e5581f-1938-47b7-a23a-c65c70c4a26d';

/// Called with this phone's OneSignal subscription id whenever it changes;
/// null or `local-…` until OneSignal's servers have registered the phone.
typedef RemotePushObserver = void Function(String? subscriptionId);

/// The server's pushes, through OneSignal on iOS and Android: missed tasks,
/// a task someone else put off, invitations and answers. The reminders at a
/// task's time are not here: the phone sets those itself
/// (`PhoneNotifications`), so they come without a network.
///
/// The only way into the OneSignal SDK: nothing else in the app imports it.
abstract interface class RemotePush {
  /// Starts OneSignal; once, before the app's first frame, after
  /// `PhoneNotifications.initialize` (so both answer the phone's
  /// notification taps).
  Future<void> initialize();

  /// Ties this phone to the signed-in account, whose id is the name the
  /// server sends to (OneSignal's external id).
  Future<void> signIn(String accountId);

  /// Unties this phone from the account that signed out, so its pushes stop
  /// coming here.
  Future<void> signOut();

  /// This phone's subscription id now; see [RemotePushObserver].
  String? get subscriptionId;

  /// Calls [observer] on every change of [subscriptionId]. OneSignal keeps
  /// observers weakly: the caller keeps [observer] alive until
  /// [removeSubscriptionObserver].
  void addSubscriptionObserver(RemotePushObserver observer);

  /// Stops calling [observer].
  void removeSubscriptionObserver(RemotePushObserver observer);

  /// Asks the person, once, whether the app may show notifications; true
  /// when it may. The same permission covers the phone's own reminders.
  Future<bool> requestPermission();
}

/// Whether [subscriptionId] is one OneSignal's servers gave: the SDK uses a
/// `local-` id of its own until the phone is registered.
bool isRegisteredSubscription(String? subscriptionId) =>
    subscriptionId != null &&
    subscriptionId.isNotEmpty &&
    !subscriptionId.startsWith('local-');

/// A [RemotePush] that does nothing: the default where none is given.
class NoRemotePush implements RemotePush {
  const NoRemotePush();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> signIn(String accountId) async {}

  @override
  Future<void> signOut() async {}

  @override
  String? get subscriptionId => null;

  @override
  void addSubscriptionObserver(RemotePushObserver observer) {}

  @override
  void removeSubscriptionObserver(RemotePushObserver observer) {}

  @override
  Future<bool> requestPermission() async => false;
}

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
