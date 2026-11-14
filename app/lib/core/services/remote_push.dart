/// Called with this phone's OneSignal subscription id whenever it changes;
/// null or `local-…` until OneSignal's servers have registered the phone.
typedef RemotePushObserver = void Function(String? subscriptionId);

/// The server's pushes, through OneSignal on iOS and Android: missed tasks,
/// a task someone else put off, invitations and answers. The reminders at a
/// task's time are not here: the phone sets those itself
/// (`PhoneNotifications`), so they come without a network.
///
/// `OneSignalRemotePush` (one_signal_remote_push.dart) is the only way into
/// the OneSignal SDK: nothing else in the app imports it.
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

  /// The `kind` of each server push the person taps (OneSignal keeps the
  /// tap that opened the app until [initialize] listens).
  Stream<String> get taps;
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

  @override
  Stream<String> get taps => const Stream<String>.empty();
}
