import 'package:app/core/widgets/app_alert.dart';
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
  return showAppAlert<PatientChoice>(
    context,
    title: context.tr('account.patient_choice_title'),
    message: context.tr('account.patient_choice_body'),
    actions: <AppAlertAction<PatientChoice>>[
      AppAlertAction<PatientChoice>(
        label: context.tr('account.patient_choice_keep'),
        value: PatientChoice.keep,
        primary: true,
      ),
      AppAlertAction<PatientChoice>(
        label: context.tr('account.patient_choice_delete'),
        value: PatientChoice.delete,
        destructive: true,
      ),
      AppAlertAction<PatientChoice>(label: context.tr('account.cancel')),
    ],
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
