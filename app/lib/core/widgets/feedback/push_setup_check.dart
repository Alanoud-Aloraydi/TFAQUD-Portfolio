import 'dart:async';

import 'package:app/core/services/remote_push.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// OneSignal's setup check, in a debug build only: once OneSignal's servers
/// have registered this phone (a real subscription id, not `local-…`), one
/// dialog says the setup works, and its button asks for the notification
/// permission. The app people use never shows it; there the app asks for
/// the permission as before.
///
/// Its words are OneSignal's own check, in English, for the developer.
class PushSetupCheck extends StatefulWidget {
  const PushSetupCheck({
    super.key,
    required this.push,
    required this.navigatorKey,
    required this.child,
    this.enabled = kDebugMode,
  });

  final RemotePush push;

  /// The app's root navigator, which the dialog opens on.
  final GlobalKey<NavigatorState> navigatorKey;

  final Widget child;

  /// Whether the check runs; only in a debug build unless a test says so.
  final bool enabled;

  @override
  State<PushSetupCheck> createState() => _PushSetupCheckState();
}

class _PushSetupCheckState extends State<PushSetupCheck> {
  /// Kept here for as long as the app runs: OneSignal holds its observers
  /// weakly, and a local one would be gone before it is called.
  late final RemotePushObserver _observer = _check;

  /// The dialog shows once per run.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    widget.push.addSubscriptionObserver(_observer);
    // The id may be there before the observer: look at it now too.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _check(widget.push.subscriptionId),
    );
  }

  @override
  void dispose() {
    widget.push.removeSubscriptionObserver(_observer);
    super.dispose();
  }

  void _check(String? subscriptionId) {
    if (_shown || !mounted || !isRegisteredSubscription(subscriptionId)) {
      return;
    }
    final BuildContext? context = widget.navigatorKey.currentContext;
    if (context == null) {
      // The first page is not up yet: try again after the next frame.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _check(subscriptionId),
      );
      return;
    }
    _shown = true;
    final Future<void> shown = showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialog) => CupertinoAlertDialog(
        title: const Text('Your OneSignal SDK integration is complete!'),
        content: const Text(
          'You can now send Push Notifications & In-App Messages through '
          'OneSignal. Tap below to enable push notifications.',
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(dialog).pop();
              unawaited(widget.push.requestPermission());
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
    unawaited(shown);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
