import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Asks to confirm signing out. True means go ahead.
///
/// Signing back in needs a code by message, so a stray tap is expensive;
/// leaving a circle and deleting the account ask first, and this asks too.
Future<bool?> askSignOutConfirmation(BuildContext context) {
  return showAppAlert<bool>(
    context,
    title: context.tr('auth.sign_out_title'),
    message: context.tr('auth.sign_out_message'),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('auth.sign_out'),
        value: true,
        destructive: true,
      ),
    ],
  );
}
