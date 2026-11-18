import 'package:app/features/account/presentation/widgets/destructive_confirm_dialog.dart';
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
