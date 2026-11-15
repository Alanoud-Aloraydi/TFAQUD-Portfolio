import 'dart:async';

import 'package:app/core/services/remote_push.dart';
import 'package:flutter/cupertino.dart';

/// OneSignal's own check dialog, in English for the developer: the setup
/// works, and its button asks for the notification permission.
class PushSetupDialog extends StatelessWidget {
  const PushSetupDialog({super.key, required this.push});

  final RemotePush push;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Your OneSignal SDK integration is complete!'),
      content: const Text(
        'You can now send Push Notifications & In-App Messages through '
        'OneSignal. Tap below to enable push notifications.',
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(push.requestPermission());
          },
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
