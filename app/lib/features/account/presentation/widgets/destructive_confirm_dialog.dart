import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A question with two answers, the yes in the red of a destructive action:
/// the title, body and button words are keys. True when the person said yes.
Future<bool?> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String yes,
  String no = 'common.cancel',
}) {
  return showAppAlert<bool>(
    context,
    title: context.tr(title),
    message: context.tr(body),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(label: context.tr(no), value: false),
      // Each of these deletes or cancels for good: the red of a
      // destructive action.
      AppAlertAction<bool>(
        label: context.tr(yes),
        value: true,
        destructive: true,
      ),
    ],
  );
}
