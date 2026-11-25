/// Called with this phone's OneSignal subscription id whenever it changes;
/// null or `local-…` until OneSignal's servers have registered the phone.
typedef RemotePushObserver = void Function(String? subscriptionId);

/// The server's pushes, through OneSignal on iOS and Android: missed tasks,
/// a task someone else put off, invitations and answers, and the reminders
/// at a task's time once the server sends them to this phone
/// (`ServerReminders`; until then the phone sets those itself, through
/// `PhoneNotifications`).
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

  /// Whether OneSignal shows this phone the server's pushes now: the phone
  /// allows notifications and the app's switch is on (opted in). Only then
  /// may the phone leave its reminders to the server.
  bool get receivesPushes;

  /// Calls [observer] on every change of [subscriptionId]. OneSignal keeps
  /// observers weakly: the caller keeps [observer] alive until
  /// [removeSubscriptionObserver].
  void addSubscriptionObserver(RemotePushObserver observer);

  /// Stops calling [observer].
  void removeSubscriptionObserver(RemotePushObserver observer);

  /// Asks the person, once, whether the app may show notifications; true
  /// when it may. The same permission covers the phone's own reminders.
  Future<bool> requestPermission();

  /// Follows the app's own notifications switch: off stops the server's
  /// pushes to this phone too; on lets them come again, once the phone
  /// allows notifications (never asking for it here).
  Future<void> setWanted(bool wanted);

  /// Each server push the person taps, as push_target.dart writes it: its
  /// `kind` and the item it is about, or a reminder's own tap (OneSignal
  /// keeps the tap that opened the app until [initialize] listens).
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
  bool get receivesPushes => false;

  @override
  void addSubscriptionObserver(RemotePushObserver observer) {}

  @override
  void removeSubscriptionObserver(RemotePushObserver observer) {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> setWanted(bool wanted) async {}

  @override
  Stream<String> get taps => const Stream<String>.empty();
}
