import 'package:app/core/constants/app_colors.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Delete your account?" True when the person agreed.
Future<bool?> showDeleteConfirmDialog(BuildContext context) {
  return _confirm(
    context,
    title: 'account.delete_title',
    body: 'account.delete_body',
    yes: 'account.delete_confirm',
  );
}

/// The account is the patient of a circle: delete it with the account, or keep
/// it. Null when the person stopped.
Future<PatientChoice?> showPatientChoiceDialog(BuildContext context) {
  return showDialog<PatientChoice>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      title: Text(context.tr('account.patient_choice_title')),
      content: Text(context.tr('account.patient_choice_body')),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(PatientChoice.keep),
          child: Text(context.tr('account.patient_choice_keep')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(PatientChoice.delete),
          style: TextButton.styleFrom(foregroundColor: AppColors.dangerInk),
          child: Text(context.tr('account.patient_choice_delete')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('account.cancel')),
        ),
      ],
    ),
  );
}

/// The account is the only manager of a circle: delete those circles too, or
/// stop. True when the person agreed.
Future<bool?> showLastManagerDialog(BuildContext context) {
  return _confirm(
    context,
    title: 'account.last_manager_title',
    body: 'account.last_manager_body',
    yes: 'account.last_manager_confirm',
  );
}

/// "Cancel this request?" asked of the person who sent it. True when they
/// agreed.
Future<bool?> showCancelRequestDialog(BuildContext context) {
  return _confirm(
    context,
    title: 'circles.cancel_confirm_title',
    body: 'circles.cancel_confirm_body_sender',
    yes: 'circles.cancel_confirm_yes',
    no: 'circles.cancel_confirm_no',
  );
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String yes,
  String no = 'account.cancel',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      title: Text(context.tr(title)),
      content: Text(context.tr(body)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr(no)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.dangerInk),
          child: Text(context.tr(yes)),
        ),
      ],
    ),
  );
}
