import 'package:app/core/services/remote_push.dart';

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
