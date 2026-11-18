import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
      AppAlertAction<PatientChoice>(label: context.tr('common.cancel')),
    ],
  );
}
