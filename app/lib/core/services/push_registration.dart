import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/remote_push.dart';

/// Ties this phone to the signed-in account for the server's pushes
/// (OneSignal, on iOS and Android), so it can tell the person about
/// invitations, requests, answers and missed tasks while the app is closed.
class PushRegistration {
  PushRegistration(this._phone, {this._remote = const NoRemotePush()});

  final PhoneNotifications _phone;

  final RemotePush _remote;

  /// Called once the person's home is read: signs this phone in to
  /// OneSignal as [accountId], then asks once whether the app may show
  /// notifications (later calls answer at once).
  Future<void> start({required String accountId}) async {
    try {
      await _remote.signIn(accountId);
    } on Exception {
      // OneSignal not reachable now: the next start signs in again.
    }
    await _phone.requestPermission();
  }
}
