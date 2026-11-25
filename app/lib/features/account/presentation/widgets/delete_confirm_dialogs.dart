import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Delete your account?" True when the person agreed.
Future<bool?> showDeleteConfirmDialog(BuildContext context) {
  return confirmDestructive(
    context,
    title: 'account.delete_title',
    body: 'account.delete_body',
    yes: 'account.delete_confirm',
  );
}

/// The account is the only manager of a circle: delete those circles too, or
/// stop. True when the person agreed.
Future<bool?> showLastManagerDialog(BuildContext context) {
  return confirmDestructive(
    context,
    title: 'account.last_manager_title',
    body: 'account.last_manager_body',
    yes: 'account.last_manager_confirm',
  );
}

/// "Cancel this request?" asked of the person who sent it. True when they
/// agreed.
Future<bool?> showCancelRequestDialog(BuildContext context) {
  return confirmDestructive(
    context,
    title: 'circles.cancel_confirm_title',
    body: 'circles.cancel_confirm_body_sender',
    yes: 'circles.cancel_confirm_yes',
    no: 'circles.cancel_confirm_no',
  );
}

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
