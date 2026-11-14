import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Gives the server this phone's Apple push token, so it can tell the person
/// about invitations, requests and answers while the app is closed.
///
/// Apple gives a token only to an app signed with a paid Apple Developer
/// account that has the Push Notifications capability. With the free
/// account iOS refuses quietly: no token, no question to the person, and
/// nothing else happens. Once the app has the capability, the same code
/// gets a token, asks to show notifications, and sends the token.
///
/// It also signs the account in to [RemotePush] (OneSignal), on iOS and
/// Android, so the server's pushes through OneSignal find this phone.
class PushRegistration {
  PushRegistration(
    this._phone,
    this._sendToken, {
    this._remote = const NoRemotePush(),
  });

  static const MethodChannel channel = MethodChannel('tafaqod/push');

  final PhoneNotifications _phone;

  /// Sends the token to the server (PUT /accounts/me/push-device).
  final Future<void> Function(String token) _sendToken;

  final RemotePush _remote;

  bool _listening = false;

  /// Asks iOS for the token. Called once the person is signed in; iOS
  /// answers through [channel] (`token`, or `tokenError` without the
  /// capability). With [accountId], also signs this phone in to
  /// [RemotePush] as that account.
  Future<void> start({String? accountId}) async {
    if (accountId != null) {
      try {
        await _remote.signIn(accountId);
      } on Exception {
        // OneSignal not reachable now: the next start signs in again.
      }
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!_listening) {
      _listening = true;
      channel.setMethodCallHandler(_onCall);
    }
    try {
      await channel.invokeMethod<void>('register');
    } on PlatformException {
      // Nothing to do: no push on this phone.
    } on MissingPluginException {
      // An older app build without the channel.
    }
  }

  Future<void> _onCall(MethodCall call) async {
    final Object? token = call.arguments;
    if (call.method == 'token' && token is String && token.isNotEmpty) {
      await received(token);
    }
  }

  /// A token arrived: push works on this phone. iOS asks the person once
  /// whether the app may show notifications, then the token goes to the
  /// server. A failed send is tried again at the next sign-in or start.
  @visibleForTesting
  Future<void> received(String token) async {
    await _phone.requestPermission();
    try {
      await _sendToken(token);
    } on Exception {
      // Offline or refused: the next start sends it again.
    }
  }
}
